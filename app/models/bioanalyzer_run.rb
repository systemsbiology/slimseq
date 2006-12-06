class BioanalyzerRun < ActiveRecord::Base
  has_many :quality_traces, :dependent => :destroy

  def BioanalyzerRun.import_new
    # not sure why this is necessary, but without it
    # a NameError occurs when trying to do
    # QualityTrace.new below
    require 'quality_trace'
        
    #bioanalyzer_pickup_location = "/users/bmarzolf/tmp/bioa_test"
    bioanalyzer_pickup_location = SiteConfig.bioanalyzer_pickup
    
    # get a list of the XML and JPG files
    xml_file_pattern = File.join(bioanalyzer_pickup_location,"/","**", "*.xml")
    xml_files = Dir.glob(xml_file_pattern)
    jpg_file_pattern = File.join(bioanalyzer_pickup_location,"/","**", "*.jpg")
    jpg_files = Dir.glob(jpg_file_pattern)

    # find all the bioanalyzer runs that are already in the database
    existing_runs = BioanalyzerRun.find(:all)
    existing_run_names = Array.new
    for run in existing_runs
      existing_run_names << run.name
    end
    
    for xml_file in xml_files
      # name of run is filename minus extension
      run_name = xml_file.scan(/.*\/(.*?)\.xml/i).to_s

      # only process xml files that haven't been loaded yet
      if( !existing_run_names.include?(run_name) )
        # get chip name
        file_root = xml_file.scan(/(.*?)\.xml/i).to_s

        # parse XML
        doc = REXML::Document.new( File.new(xml_file) )
        
        # find the chip-wide lab group
        chip_lab_name = doc.elements["Chipset/Chips/Chip/Files/File/FileInformation/Comment"].text

		if( chip_lab_name != nil )
	        # get rid of trailing whitespace
	        chip_lab_name = chip_lab_name.scan(/(.*)\n*/)[0]
	        chip_lab_group = LabGroup.find(:first, :conditions => [ "name = ?", chip_lab_name])
    	end
    
        # create an array to hold traces
        traces = Array.new
        
        quality_rating = 0
        concentration = 0
        ribosomal_ratio = 0
        
        # grab each sample-specific node in the XML
        doc.elements.each("Chipset/Chips/Chip/Files/File/Samples/Sample") do |node|
          # only use lanes that have data
          if( node.elements["HasData"].text == "true" )
            number = node.elements["WellNumber"].text

            # figure out sample name and type
            full_name = node.elements["Name"].text
            if( full_name.downcase.match(/(.*)_(total|crna|frag|fragmented)/) != nil )
              elements = full_name.split(/_/)
              type = elements.pop
              name = elements.join("_")
            elsif( full_name.downcase.match(/(.*)\ (total|crna|frag|fragmented)/) != nil )
              elements = full_name.split(/ /)
              type = elements.pop
              name = elements.join(" ")
            else
              name = full_name
            end

            concentration = 
              node.elements["DAResultStructures/DARConcentration/Channel/TotalConcentration"].text
  
            # look for sample-specific lab group
            lab_name = node.elements["Comment"].text
            lab_group = nil
            if(lab_name != nil)
              lab_group = LabGroup.find(:first, :conditions => [ "name LIKE ?", lab_name])
            end
            # if there wasn't a spcific lab group specified for this sample,
            # try to use the chip-wide lab group
            if(lab_group == nil)
              lab_group = chip_lab_group
            end
            
            # need to treat ladder differently
            if( name == "Ladder")
              # associate a jpeg
              current_jpg_file = file_root + "_EGRAM_Ladder.jpg"
  
              # set type as Ladder
              type = "ladder"
            else
              # associate a jpeg
              current_jpg_file = file_root + "_EGRAM_Sample" + number + ".jpg"
  
              quality_rating = node.elements["DAResultStructures/DARRIN/Channel/RIN"].text
              ribosomal_ratio =
                node.elements["DAResultStructures/DARFragment/Channel/rRNARatio"].text
            end
  
            # ensure that sample is tagged with a type, and that image exists
            if( type != nil && lab_group != nil && jpg_files.include?(current_jpg_file) )
              # create new image name, and drop spaces to make the URL easier
              new_image_name = "#{run_name}-#{name}-#{type}.jpg".tr(" ","")
              image_path = "/quality_traces/#{new_image_name}"
              
              FileUtils.cp( current_jpg_file, "#{RAILS_ROOT}/public#{image_path}")
            
              trace = QualityTrace.new(:image_path => image_path,
                                       :quality_rating => quality_rating,
                                       :name => name,
                                       :number => number,
                                       :sample_type => type,
                                       :concentration => concentration,
                                       :ribosomal_ratio => ribosomal_ratio,
                                       :lab_group_id => lab_group.id
                                       )
              traces << trace
            end
          end
        end
        
        # only save bioanalyzer_run if there are > 1 samples (more than just ladder)
        if( traces.size > 1 )
          # grab the date from the XML
          time_date = doc.elements["Chipset/Chips/Chip/ChipInformation/CreationDate"].text
          date = time_date.scan(/(\d{4}\-\d{2}\-\d{2}).*/).to_s
                  
          run = BioanalyzerRun.new(:name => run_name,
                                   :date => date
                                   )
          
          # save the traces if the run itself saves
          if( run.save )
            for trace in traces
              trace.bioanalyzer_run_id = run.id
              trace.save
            end
          end
        end
      end
    end
  end

  def destroy_warning
    quality_traces = QualityTrace.find(:all, :conditions => ["bioanalyzer_run_id = ?", id])
    
    return "Destroying this Bioanalyzer Run will also destroy:\n" + 
           quality_traces.size.to_s + " trace(s)\n" +
           "Are you sure you want to destroy it?"
  end

end
