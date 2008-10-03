class Sample < ActiveRecord::Base
  require 'spreadsheet/excel'
  require 'parseexcel'
  require 'csv'
  include Spreadsheet
  
  belongs_to :user, :foreign_key => "submitted_by_id"
  belongs_to :organism
  belongs_to :naming_scheme
  belongs_to :sample_prep_kit
  belongs_to :reference_genome
  
  has_many :sample_terms, :dependent => :destroy
  has_many :sample_texts, :dependent => :destroy
  
  validates_presence_of :sample_name, :short_sample_name, :submission_date
  validates_length_of :short_sample_name, :maximum => 20
  validates_length_of :sample_name, :maximum => 59
  validates_length_of :status, :maximum => 50

  attr_accessor :naming_element_selections, :naming_element_visibility,
    :text_values, :schemed_name
  
  def validate
    # make sure date/short_sample_name/sample_name combo is unique
    s = Sample.find_by_submission_date_and_short_sample_name_and_sample_name(
        submission_date, short_sample_name, sample_name)
    if( s != nil && s.id != id )
      errors.add("Duplicate submission date/short_sample_name/sample_name")
    end
    
    # look for all the things that infuriate GCOS or SBEAMS:
    # * non-existent sample name
    # * spaces
    # * characters other than underscores and dashes
    if sample_name == nil
      errors.add("Sample name must be supplied")
    elsif sample_name[/\ /] != nil ||
        sample_name[/\+/] != nil ||
        sample_name[/\&/] != nil ||
        sample_name[/\#/] != nil ||
        sample_name[/\(/] != nil ||
        sample_name[/\)/] != nil ||
        sample_name[/\//] != nil ||
        sample_name[/\\/] != nil
      errors.add("Sample name must contain only letters, numbers, underscores and dashes or it")
    end
  end
  
  def populate_default_visibilities_and_texts
    if(naming_scheme_id != nil)
      self.naming_element_visibility = naming_scheme.default_visibilities
      self.text_values = naming_scheme.default_texts
    end
  end
  
  def self.to_csv(naming_scheme = "")
    ###########################################
    # set up spreadsheet
    ###########################################
    
    csv_file_name = "#{RAILS_ROOT}/tmp/csv/samples_" +
      "#{Date.today.to_s}-#{naming_scheme}.csv"
    
    csv_file = File.open(csv_file_name, 'wb')
    CSV::Writer.generate(csv_file) do |csv|
      if(naming_scheme == "")
        csv << [ "CEL File",
          "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Organism",
          "Naming Scheme"
        ]

        samples = Sample.find( :all, :conditions => {:naming_scheme_id => nil},
          :include => [:organism], :order => "samples.id ASC" )

        for sample in samples
          if(sample.hybridization != nil)
            cel_file = sample.hybridization.raw_data_path
          else
            cel_file = ""
          end
          csv << [ cel_file,
            sample.id,
            sample.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.organism.name,
            "None"
          ]
        end
      else
        scheme = NamingScheme.find(:first, :conditions => { :name => naming_scheme })
        
        if(scheme.nil?)
          return nil
        end
        
        # stock headings
        headings = [ "CEL File",
          "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Organism",
          "Naming Scheme"
        ]

        # headings for naming elements
        naming_elements = 
          scheme.naming_elements.find(:all, :order => "element_order ASC")
        naming_elements.each do |e|
          headings << e.name
        end

        csv << headings

        samples = Sample.find( :all, 
          :conditions => {:naming_scheme_id => scheme.id},
          :include => [:organism],
          :order => "samples.id ASC" )

        current_row = 0
        for sample in samples
          if(sample.hybridization != nil)
            cel_file = sample.hybridization.raw_data_path
          else
            cel_file = ""
          end
          column_values = [ cel_file,
            sample.id,
            sample.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.organism.name,
            sample.naming_scheme.name
          ]
          # values for naming elements
          naming_elements.each do |e|
            value = ""
            if(e.free_text == true)
              sample_text = SampleText.find(:first, 
                :conditions => {:sample_id => sample.id,
                  :naming_element_id => e.id})
              if(sample_text != nil)
                value = sample_text.text
              end
            else
              sample_term = SampleTerm.find(:first,
                :include => :naming_term,
                :conditions => ["sample_id = ? AND naming_terms.naming_element_id = ?",
                  sample.id, e.id] )
              if(sample_term != nil)
                value = sample_term.naming_term.term
              end
            end
            column_values << value
          end

          csv << column_values
        end
      end    
    end
  
    csv_file.close
     
    return csv_file_name
  end

  def self.from_csv(csv_file_name)

    row_number = 0

    CSV.open(csv_file_name, 'r') do |row|
      # don't process header row
      if(row_number > 0)
        begin
          sample = Sample.find(row[1].to_i)
        rescue
          return "Sample ID is invalid in row #{row_number}"
        end
      
        # check to see if this sample should have a naming scheme
        if(row[10] == "None")
          ###########################################
          # non-naming schemed sample
          ###########################################
        
          # there should be 10 cells in each row
          if(row.size != 11)
            return "Wrong number of columns in row #{row_number}. Expected 11"
          end

          sample.destroy_existing_naming_scheme_info
        
          errors = sample.update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number} of non-naming schemed samples"
          end
        else
          ###########################################
          # naming schemed samples
          ###########################################

          naming_scheme = NamingScheme.find(:first, 
            :conditions => {:name => row[10]})
          # make sure this sample has a naming scheme
          if(naming_scheme.nil?)
            return "Naming scheme #{row[10]} doesn't exist in row #{row_number}"
          end

          naming_elements =
            naming_scheme.naming_elements.find(:all, :order => "element_order ASC")

          expected_columns = 11 + naming_elements.size
          if(row.size != expected_columns)
            return "Wrong number of columns in row #{row_number}. " +
              "Expected #{expected_columns}"
          end

          sample.destroy_existing_naming_scheme_info
        
          # update the sample attributes
          errors = sample.update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number}"
          end

          # update the naming scheme records
          current_column_index = 11
          naming_elements.each do |e|
            # do nothing if there's nothing in the cell
            if(row[current_column_index] != nil)
              if(e.free_text == true)
                sample_text = SampleText.new(
                  :sample_id => sample.id,
                  :naming_element_id => e.id,
                  :text => row[current_column_index]
                )
                if(!sample_text.save)
                  return "Unable to create #{e.name} for row #{row_number}"
                end
              else
                naming_term = NamingTerm.find(:first, 
                  :conditions => ["naming_element_id = ? AND " +
                    "(term = ? OR abbreviated_term = ?)",
                    e.id,
                    row[current_column_index],
                    row[current_column_index] ])
                # if naming term wasn't found,
                # match leading 0's if there are any
                if(naming_term.nil?)
                  naming_term = NamingTerm.find(:first, 
                    :conditions => ["naming_element_id = ? AND " +
                      "(term REGEXP ? OR abbreviated_term REGEXP ?)",
                      e.id,
                      "0*" + row[current_column_index],
                      "0*" + row[current_column_index] ])
                end
                if(naming_term.nil?)
                  return "Naming term #{row[current_column_index]} doesn't " +
                    "exist for #{e.name} for row #{row_number}"
                end
                sample_term = SampleTerm.new(
                  :sample_id => sample.id,
                  :naming_term_id => naming_term.id
                )
                if(!sample_term.save)
                  return "Unable to create #{e.name} for row #{row_number}"
                end
              end
            end
            current_column_index += 1
          end
          sample.update_attributes(:naming_scheme_id => naming_scheme.id)
        end
      end
      row_number += 1
    end

    return ""
  end

  def destroy_existing_naming_scheme_info
    SampleText.find(:all, 
      :conditions => {:sample_id => id}
    ). each do |st|
      st.destroy
    end
    SampleTerm.find(:all, 
      :conditions => {:sample_id => id}
    ). each do |st|
      st.destroy
    end
  end

  def update_unschemed_columns(row)  
    organism = Organism.find(:first, :conditions => { :name => row[7] })
    if(organism.nil?)
      organism = Organism.create(:name => row[7])
    end
    
    project = Project.find(:first, :conditions => { :name => row[9] })
    if(project.nil?)
      return "Project doesn't exist"
    end

    if(!update_attributes(
          :submission_date => row[2],
          :short_sample_name => row[3],
          :sample_name => row[4],
          :organism_id => organism.id
        ))
      puts errors.full_messages
      return "Problem updating values for sample id=#{id}: #{errors.full_messages}"
    end
    
    return ""
  end
end
