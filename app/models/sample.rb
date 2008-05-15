class Sample < ActiveRecord::Base
  require 'spreadsheet/excel'
  require 'parseexcel'
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
  
  def self.to_excel
    ###########################################
    # set up spreadsheet
    ###########################################
    
    puts "VERSION: " + Excel::VERSION
    
    workbook_name = "#{RAILS_ROOT}/tmp/excel/samples_" + Date.today.to_s +
      ".xls"
    
    workbook = Excel.new(workbook_name)
    # doing each side individually, since :border => 1 is giving an error
    bordered = Format.new( :bottom => 1,
                           :top => 1,
                           :left => 1,
                           :right => 1 )
    bordered_bold = Format.new( :bottom => 1,
                                :top => 1,
                                :left => 1,
                                :right => 1,
                                :bold => true )
    workbook.add_format(bordered)
    workbook.add_format(bordered_bold)
    
    ###########################################
    # tab for non-naming schemed samples
    ###########################################
    
    unschemed = workbook.add_worksheet("no naming scheme")

    
    unschemed.write_row 0, 0, [ "Sample ID",
                                "Submission Date",
                                "Short Sample Name",
                                "Sample Name",
                                "Sample Group Name",
                                "Chip Type",
                                "Organism",
                                "SBEAMS User",
                                "Project",
                                "Status",
                              ], bordered

    samples = Sample.find( :all, :conditions => {:naming_scheme_id => nil},
      :include => [:project, :chip_type, :organism], :order => "samples.id ASC" )
    
    current_row = 0
    for sample in samples
      unschemed.write_row current_row+=1, 0, [ sample.id,
                                             sample.submission_date.to_s,
                                             sample.short_sample_name,
                                             sample.sample_name,
                                             sample.sample_group_name,
                                             sample.chip_type.name,
                                             sample.organism.name,
                                             sample.sbeams_user,
                                             sample.project.name,
                                             sample.status
      ], bordered
    end

    ###########################################
    # tabs for naming schemed samples
    ###########################################
    
    schemes = NamingScheme.find(:all, :order => "name ASC")
    schemes.each do |scheme|
      worksheet = workbook.add_worksheet(scheme.name)

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
        "Status",
      ]

      # headings for naming elements
      scheme.naming_elements.each do |e|
        headings << e.name
      end
      
      worksheet.write_row 0, 0, headings, bordered

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
          sample.project.name,
          sample.status
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
        
        worksheet.write_row current_row+=1, 0, column_values, bordered
      end
    end    
    
    workbook.close
    
    return workbook_name
  end
end
