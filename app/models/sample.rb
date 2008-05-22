class Sample < ActiveRecord::Base
  require 'spreadsheet/excel'
  require 'parseexcel'
  require 'csv'
  include Spreadsheet
  
  has_one :hybridization, :dependent => :destroy

  belongs_to :chip_type
  belongs_to :project
  belongs_to :organism
  belongs_to :starting_quality_trace, :class_name => "QualityTrace", :foreign_key => "starting_quality_trace_id"
  belongs_to :amplified_quality_trace, :class_name => "QualityTrace", :foreign_key => "amplified_quality_trace_id"
  belongs_to :fragmented_quality_trace, :class_name => "QualityTrace", :foreign_key => "fragmented_quality_trace_id"
  belongs_to :naming_scheme
  
  has_many :sample_terms, :dependent => :destroy
  has_many :sample_texts, :dependent => :destroy
  
  validates_associated :chip_type, :project
  validates_presence_of :sample_name, :short_sample_name, :submission_date, :project_id
  #  validates_uniqueness_of :sample_name
  validates_length_of :short_sample_name, :maximum => 20
  validates_length_of :sample_name, :maximum => 59
  validates_length_of :sbeams_user, :maximum => 20
  validates_length_of :status, :maximum => 50

  attr_accessor :naming_element_selections, :naming_element_visibility,
    :text_values
  
  def validate_on_create
    # make sure date/short_sample_name/sample_name combo is unique
    if Sample.find_by_submission_date_and_short_sample_name_and_sample_name(
        submission_date, short_sample_name, sample_name)
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
  
  def self.to_csv(naming_scheme = "")
    ###########################################
    # set up spreadsheet
    ###########################################
    
    csv_file_name = "#{RAILS_ROOT}/tmp/csv/samples_" +
      "#{Date.today.to_s}-#{naming_scheme}.csv"
    
    csv_file = File.open(csv_file_name, 'wb')
    CSV::Writer.generate(csv_file) do |csv|
      if(naming_scheme == "")
        csv << [  "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Sample Group Name",
          "Chip Type",
          "Organism",
          "SBEAMS User",
          "Project",
        ]

        samples = Sample.find( :all, :conditions => {:naming_scheme_id => nil},
          :include => [:project, :chip_type, :organism], :order => "samples.id ASC" )

        current_row = 0
        for sample in samples
          csv << [ sample.id,
            sample.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.sample_group_name,
            sample.chip_type.name,
            sample.organism.name,
            sample.sbeams_user,
            sample.project.name,
          ]
        end
      else
        scheme = NamingScheme.find(:first, :conditions => { :name => naming_scheme })
        
        if(scheme.nil?)
          return nil
        end
        
        # stock headings
        headings = [ "Sample ID",
          "Submission Date",
          "Short Sample Name",
          "Sample Name",
          "Sample Group Name",
          "Chip Type",
          "Organism",
          "SBEAMS User",
          "Project",
        ]

        # headings for naming elements
        scheme.naming_elements.each do |e|
          headings << e.name
        end

        csv << headings

        samples = Sample.find( :all, 
          :conditions => {:naming_scheme_id => scheme.id},
          :include => [:project, :chip_type, :organism],
          :order => "samples.id ASC" )

        current_row = 0
        for sample in samples
          column_values = [ sample.id,
            sample.submission_date.to_s,
            sample.short_sample_name,
            sample.sample_name,
            sample.sample_group_name,
            sample.chip_type.name,
            sample.organism.name,
            sample.sbeams_user,
            sample.project.name
          ]
          # values for naming elements
          scheme.naming_elements.each do |e|
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
                :conditions => ["sample_id = ? AND naming_element_id = ?",
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

  def self.from_csv(csv_file_name, schemed = false)

    if(schemed == false)
      ###########################################
      # non-naming schemed samples
      ###########################################

      row_number = 0
      CSV.open(csv_file_name, 'r') do |row|
        # don't process header row
        if(row_number > 0)
          # there should be 10 cells in each row
          if(row.size != 9)
            return "Wrong number of columns in row #{row_number} of non-naming schemed samples"
          end

          errors = update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number} of non-naming schemed samples"
          end
        end
        
        row_number += 1
      end
    else
      ###########################################
      # naming schemed samples
      ###########################################
    
      row_number = 0
      CSV.open(csv_file_name, 'r') do |row|
        # don't process header row
        if(row_number > 0)
          begin
            sample = Sample.find(row[0].to_i)
          rescue
            return "Sample ID is invalidin row #{row_number} for tab #{current_worksheet}"
          end

          # make sure this sample has a naming scheme
          if(sample.naming_scheme_id.nil?)
            return "Naming scheme expected in row #{row_number} for tab #{current_worksheet}"
          end

          naming_scheme = sample.naming_scheme
          naming_elements = naming_scheme.naming_elements

          if(row.size != 9 + naming_elements.size)
            return "Wrong number of columns in row #{row_number} for tab #{current_worksheet}"
          end

          # update the sample attributes
          errors = update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number} for tab #{current_worksheet}"
          end

          # update the naming scheme records
          current_column_index = 9
          naming_elements.each do |e|
            if(e.free_text == true)
              sample_text = SampleText.find(:first, 
                :conditions => {:sample_id => sample.id,
                  :naming_element_id => e.id})
              if(!sample_text.update_attribute('text',
                    row[current_column_index]) )
                return "Unable to update #{e.name} for row #{row_number}" +
                  " for tab #{current_worksheet}"
              end
            else
              sample_term = SampleTerm.find(:first,
                :include => :naming_term,
                :conditions => ["sample_id = ? AND naming_element_id = ?",
                  sample.id, e.id] )
              new_naming_term = NamingTerm.find(:first, 
                :conditions => ["term = ? OR abbreviated_term = ?", 
                  row[current_column_index],
                  row[current_column_index] ])
              if(new_naming_term.nil?)
                return "Naming term doesn't exist for #{e.name} for row #{row_number}" +
                  " for tab #{current_worksheet}"
              end
              if(!sample_term.update_attribute('naming_term_id',
                    new_naming_term.id))
                return "Unable to update #{e.name} for row #{row_number}" +
                  " for tab #{current_worksheet}"
              end
            end

            current_column_index += 1
          end
        end
        
        row_number += 1
      end
    end

    return ""
  end

  private

  def self.update_unschemed_columns(row)
    # have to use error blocks since unexpected values can cause exceptions
    # to be raised

    begin
      sample = Sample.find(row[0].to_i)
    rescue
      return "Sample ID is invalid"
    end
    
    chip_type = ChipType.find(:first, 
      :conditions => [ "name = ? OR short_name = ?", row[5], row[5] ])
    if(chip_type.nil?)
      return "Chip type doesn't exist"
    end
    
    organism = Organism.find(:first, :conditions => { :name => row[6] })
    if(organism.nil?)
      organism = Organism.create(:name => row[6])
    end
    
    project = Project.find(:first, :conditions => { :name => row[8] })
    if(project.nil?)
      return "Project doesn't exist"
    end
    
    if(!sample.update_attributes(
          :submission_date => row[1],
          :short_sample_name => row[2],
          :sample_name => row[3],
          :sample_group_name => row[4],
          :chip_type_id => chip_type.id,
          :organism_id => organism.id,
          :sbeams_user => row[7],
          :project_id => project.id
        ))
      return "Problem updating values"
    end
    
    return ""
  end
end
