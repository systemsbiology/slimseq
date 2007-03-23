class HybridizationsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    populate_arrays_from_tables
  
    @hybridizations = Hybridization.find(:all, :order => "hybridization_date DESC, chip_number ASC", 
                                         :include => { :sample => :project } )
  end

  def new
    populate_arrays_from_tables

    @available_samples = Sample.find(:all, :conditions => [ "status = 'submitted'" ],
                                     :order => "submission_date DESC, id ASC")
  
    # clear out hybridization record since this is a 'new' set
    session[:hybridizations] = Array.new
    session[:hybridization_number] = 0
  
    @submit_hybridizations = SubmitHybridizations.new
  end

  def add
    populate_arrays_from_tables
  
    @submit_hybridizations = SubmitHybridizations.new

    # build Array of Sample objects from the checkboxes
    # in the sample list
    selected_samples = params[:selected_samples]
    @samples = Array.new
    if selected_samples != nil
      for sample_id in selected_samples.keys
        if selected_samples[sample_id] == '1'
          @samples << Sample.find(sample_id)
        end
      end
    end
    
    @hybridizations = session[:hybridizations]
    current_hyb_number = session[:hybridization_number]
    @submit_hybridizations = SubmitHybridizations.new(params[:submit_hybridizations])

    # only add more hyb slots if that's what was asked
    if(@submit_hybridizations.valid?) 
      for sample in @samples
        project = sample.project
        # does user want charge set(s) created based on projects?
        if(@submit_hybridizations.charge_set_id == -1)
          @charge_set = ChargeSet.find(:first, :conditions => ["name = ? AND lab_group_id = ? AND budget = ?",
                                       project.name, project.lab_group_id, project.budget])
          # see if new charge set need to be created
          if(@charge_set == nil)
            # get latest charge period
            charge_period = ChargePeriod.find(:first, :order => "id DESC")

            # if no charge periods exist, make a default one
            if( charge_period == nil )
              charge_period = ChargePeriod.new(:name => "Default Charge Period")
              charge_period.save
            end
            
            @charge_set = ChargeSet.new(:charge_period_id => charge_period.id,
                                        :name => project.name,
                                        :lab_group_id => project.lab_group_id,
                                        :budget => project.budget
                                        )
            @charge_set.save
          end
          
          @submit_hybridizations.charge_set_id = @charge_set.id
        end
        current_hyb_number += 1
        @hybridizations << Hybridization.new(:hybridization_date => @submit_hybridizations.hybridization_date,      
              :chip_number => current_hyb_number,
              :charge_set_id => @submit_hybridizations.charge_set_id,
              :charge_template_id => @submit_hybridizations.charge_template_id,
              :sample_id => sample.id)
      end
      session[:hybridizations] = @hybridizations
      session[:hybridization_number] = current_hyb_number
    end
    
    # get list of available samples, and removed ones currently in hybridization table
    @available_samples = Sample.find(:all, :conditions => [ "status = 'submitted'" ],
                                     :order => "submission_date DESC, id ASC")
    for hybridization in @hybridizations
      sample = hybridization.sample
      if( @available_samples.include?(sample) )
        @available_samples.delete(sample)
      end
    end
  end
  
  def order_hybridizations
    @order = params[:hybridization_list]
    @hybridizations = session[:hybridizations]

    # re-number hybridizations
    for n in 0..@hybridizations.size-1
      @hybridizations[@order[n].to_i-1].chip_number = n+1
    end
    @hybridizations.sort! {|x,y| x.chip_number <=> y.chip_number }

    session[:hybridizations] = @hybridizations
    render :partial => 'hybridization_list'
  end
  
  def create
    populate_arrays_from_tables  
    @hybridizations = session[:hybridizations]

    failed = false 
    for hybridization in @hybridizations
      # if any one hybridization record isn't valid,
      # we don't want to save any
      if !hybridization.valid?
        failed = true
      end
    end
    if failed
      @submit_hybridizations = SubmitHybridizations.new
      @available_samples = Sample.find(:all, :conditions => [ "status = 'submitted'" ],
                                       :order => "submission_date DESC")
      render :action => 'add'
    else
      # save now that all hybridizations have been tested as valid
      for hybridization in @hybridizations
        hybridization.save
        
        # mark sample as hybridized
        hybridization.sample.update_attributes(:status => 'hybridized')
      end
      flash[:notice] = "Hybridization records"
      if SiteConfig.track_inventory?
        # add chip transactions for these hybridizations
        record_as_chip_transactions(@hybridizations)
        flash[:notice] += ", inventory changes"
      end
      if SiteConfig.create_gcos_files?
        begin    
          # output files for automated sample/experiment loading into GCOS
          create_gcos_import_files(@hybridizations)
          flash[:notice] += ", GCOS files"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write GCOS file(s) to " + SiteConfig.gcos_output_path + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end      
      end
      if SiteConfig.track_charges?
        # record charges incurred from these hybridizations
        record_charges(@hybridizations)
        flash[:notice] += ", charges"
      end
      if SiteConfig.using_sbeams?
        begin
          # save Bioanalyzer trace images for SBEAMS
          output_trace_images(@hybridizations)
          flash[:notice] += ", bioanalyzer images"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write Bioanalyzer images to " + SiteConfig.quality_trace_dropoff + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end
      end
      if(flash[:notice] != nil)
        flash[:notice] += ' created successfully.'
      end
      redirect_to :action => 'show'
    end
  end
  
  def show
    if session[:hybridizations] == nil
      @hybridizations = Array.new
    else
      @hybridizations = session[:hybridizations]
    end
  end

  def clear
    new
    redirect_to :action => 'new'
  end

  def edit
    populate_arrays_from_tables
    @hybridization = Hybridization.find(params[:id])
    @sample = Sample.find(@hybridization.sample_id)

    @samples = Sample.find(:all, :order => "sample_name ASC")
  end

  def update
    populate_arrays_from_tables
    hybridization = Hybridization.find(params[:id])

    begin
      if hybridization.update_attributes(params[:hybridization])
        flash[:notice] = 'Hybridization was successfully updated.'
        redirect_to :action => 'list'
      else
        @samples = Sample.find(:all, :order => "sample_name ASC")
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this hybridization."
      @hybridization = Hybridization.find(params[:id])
      @sample = Sample.find(@hybridization.sample_id)
      @samples = Sample.find(:all, :order => "sample_name ASC")
      render :action => 'edit'
    end
  end

  def destroy
    hybridization = Hybridization.find(params[:id])
    sample = Sample.find(hybridization.sample_id)
    hybridization.destroy
    sample.update_attribute('status', 'submitted')
    redirect_to :action => 'list'
  end

  def bulk_handler
    selected_hybridizations = params[:selected_hybridizations]

    # make an array of the hybridizations
    hybridizations = Array.new
    for hybridization_id in selected_hybridizations.keys
      if selected_hybridizations[hybridization_id] == '1'
        hybridization = Hybridization.find(hybridization_id)
        hybridizations << hybridization
      end
    end

    # make sure some hybridizations were selected--if not, complain
    if( hybridizations.size > 0 )
      # destroy, export GCOS files, or export Bioanalyzer files?
      if( params[:commit] == "Delete Hybridizations" )
        for hybridization in hybridizations
          sample = Sample.find(hybridization.sample_id)
          hybridization.destroy
          sample.update_attribute('status', 'submitted')
        end
      elsif( params[:commit] == "Export GCOS Files" )
        begin
          create_gcos_import_files(hybridizations)
          flash[:notice] = "GCOS files successfully created"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write GCOS file(s) to " + SiteConfig.gcos_output_path + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end 
      elsif( params[:commit] == "Export Bioanalyzer Images" )
        begin
          output_trace_images(hybridizations)
          flash[:notice] = "Bioanalyzer Images output successfully"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write Bioanalyzer images to " + SiteConfig.quality_trace_dropoff + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end
      end
    else
      flash[:warning] = "No hybridizations were selected"
    end

    redirect_to :action => 'list'
  end

  def record_as_chip_transactions(hybridizations)
    hybs_per_group_chip = Hash.new(0)
    
    for hybridization in hybridizations
      sample = hybridization.sample
      hybridization_date_group_chip_key = hybridization.hybridization_date.to_s+"_"+sample.project.lab_group_id.to_s+"_"+sample.chip_type_id.to_s
      # if this hybridization_date/lab group/chip type combo hasn't been seen, create a new object to track
      # number of chips of this combo
      if hybs_per_group_chip[hybridization_date_group_chip_key] == 0
        hybs_per_group_chip[hybridization_date_group_chip_key] = ChipTransaction.new(:lab_group_id => sample.project.lab_group_id,
                              :chip_type_id => sample.chip_type_id,
                              :date => hybridization.hybridization_date,
                              :description => 'Hybridized on ' + hybridization.hybridization_date.to_s,
                              :used => 1)
      else
        hybs_per_group_chip[hybridization_date_group_chip_key][:used] += 1
      end
    end

    for hybridization_date_group_chip_key in hybs_per_group_chip.keys
      hybs_per_group_chip[hybridization_date_group_chip_key].save
    end
  end
  
  def create_gcos_import_files(hybridizations)
    for hybridization in hybridizations
      sample = hybridization.sample
      # only make hyb info record for GCOS if it's an affy array
      if sample.chip_type.array_platform == "affy"
        hybridization_date_number_string = hybridization.hybridization_date.year.to_s + ("%02d" % hybridization.hybridization_date.month) +
                             ("%02d" % hybridization.hybridization_date.day) + "_" + ("%02d" % hybridization.chip_number)
        # open an output file for writing
        gcos_file = File.new(SiteConfig.gcos_output_path + "/" + hybridization_date_number_string + 
                    "_" + sample.sample_name + ".txt", "w")

        # gather individual and group naming scheme info, if a naming scheme is being used
        if sample.naming_scheme_id != nil
          gcos_sample_info = Array.new
          gcos_experiment_info = Array.new
          
          # store the GCOS sample and experiment templates from the naming schemes
          gcos_sample_info << "SampleTemplate=" + sample.naming_scheme.name + "\n"
          gcos_experiment_info << "ExperimentTemplate=" + sample.naming_scheme.name + "\n"
          
          for sample_term in sample.sample_terms
            if(sample_term.naming_term.naming_element.group_element == true)
              gcos_sample_info << sample_term.naming_term.naming_element.name + "=" + sample_term.naming_term.term + "\n"
            else
              gcos_experiment_info << sample_term.naming_term.naming_element.name + "=" + sample_term.naming_term.term + "\n"
            end
          end
        # use default sample template of AffyCore if there's no naming scheme
        else
          gcos_file << "SampleTemplate=AffyCore\n"
        end
        
        # write out information needed by GCOS Object Importer tool
        gcos_file << "[SAMPLE]\n"
        gcos_file << "SampleName=" + sample.sample_group_name + "\n"
        gcos_file << "SampleType=" + Organism.find(sample.chip_type.organism_id).name + "\n"
        gcos_file << "SampleProject=" + sample.project.name + "\n"
        gcos_file << "SampleUser=affybot\n"
        gcos_file << "SampleUpdate=1\n"
        gcos_file << "Array User Name=" + sample.sbeams_user + "\n"
        
        # add any extra info from the naming scheme, if present
        if( gcos_sample_info != nil )
          for line in gcos_sample_info
            gcos_file << line
          end
        end
        
        gcos_file << "\n"
        gcos_file << "[EXPERIMENT]\n"
        gcos_file << "ExperimentName=" + hybridization_date_number_string + "_" + sample.sample_name + "\n"
        gcos_file << "ArrayType=" + ChipType.find(sample.chip_type_id).short_name + "\n"
        gcos_file << "ExperimentUser=affybot\n"
        gcos_file << "ExperimentUpdate=0\n"

        # add any extra info from the naming scheme, if present
        if( gcos_experiment_info != nil )
          for line in gcos_experiment_info
            gcos_file << line
          end
        end
        
        gcos_file.close
      end
    end
  end
  
  def record_charges(hybridizations)  
    for hybridization in hybridizations
      sample = hybridization.sample
      
      template = ChargeTemplate.find(hybridization.charge_template_id)
      charge = Charge.new(:charge_set_id => hybridization.charge_set_id,
                          :date => hybridization.hybridization_date,
                          :description => sample.sample_name,
                          :chips_used => template.chips_used,
                          :chip_cost => template.chip_cost,
                          :labeling_cost => template.labeling_cost,
                          :hybridization_cost => template.hybridization_cost,
                          :qc_cost => template.qc_cost,
                          :other_cost => template.other_cost)
      charge.save
    end
  end

  def output_trace_images(hybridizations)
    for hybridization in hybridizations
      sample = hybridization.sample
      hybridization_year_month = hybridization.hybridization_date.year.to_s + ("%02d" % hybridization.hybridization_date.month)
      hybridization_date_number_string =  hybridization_year_month + ("%02d" % hybridization.hybridization_date.day) + 
                                          "_" + ("%02d" % hybridization.chip_number)
      chip_name = hybridization_date_number_string + "_" + sample.sample_name

      output_path = SiteConfig.quality_trace_dropoff + "/" + hybridization_year_month
      
      # output each quality trace image if it exists
      if( sample.starting_quality_trace != nil )
        copy_image_based_on_chip_name( sample.starting_quality_trace, output_path, chip_name + ".EGRAM_T.jpg" )
      end
      if( sample.amplified_quality_trace != nil )
        copy_image_based_on_chip_name( sample.amplified_quality_trace, output_path, chip_name + ".EGRAM_PF.jpg" )
      end
      if( sample.fragmented_quality_trace != nil )
        copy_image_based_on_chip_name( sample.fragmented_quality_trace, output_path, chip_name + ".EGRAM_F.jpg" )
      end
    end
  end
  
  def copy_image_based_on_chip_name(quality_trace, output_path, image_name)
    FileUtils.cp( "#{RAILS_ROOT}/public/" + quality_trace.image_path, output_path + "/" + image_name )
  end

  private
  def populate_arrays_from_tables
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
  
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")

    # only show charge sets in the most recently entered charge period
    latest_charge_period = ChargePeriod.find(:first, :order => "id DESC")
    if(latest_charge_period == nil)
      @charge_sets = Array.new
    else
      @charge_sets = ChargeSet.find(:all, :conditions => [ "charge_period_id = ?", latest_charge_period.id ],
                                    :order => "name ASC")
    end
    
    # only show templates where a chip is hybridized, so chips_used > 0
    @charge_templates = ChargeTemplate.find(:all, :order => "name ASC",
                        :conditions => ["chips_used > ?", 0])
  end
end
