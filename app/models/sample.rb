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
  belongs_to :project
  has_and_belongs_to_many :flow_cell_lanes
  
  has_many :sample_terms, :dependent => :destroy
  has_many :sample_texts, :dependent => :destroy
  
  validates_presence_of :sample_description, :name_on_tube, :submission_date, :budget_number,
    :reference_genome_id, :sample_prep_kit_id, :desired_read_length, :project_id
  validates_numericality_of :alignment_start_position, :greater_than_or_equal_to => 1
  validates_numericality_of :alignment_end_position, :greater_than_or_equal_to => 1
  validates_numericality_of :insert_size
  
  attr_accessor :schemed_name
  
  # temporarily associates with a sample set, which doesn't get stored in db
  attr_accessor :sample_set_id
  belongs_to :sample_set

  acts_as_state_machine :initial => :submitted, :column => 'status'
  
  state :submitted
  state :clustered
  state :sequenced
  state :completed

  event :cluster do
    transitions :from => :submitted, :to => :clustered
  end

  event :uncluster do
    transitions :from => :clustered, :to => :submitted
  end
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered
  end
  
  event :complete do
    transitions :from => :sequenced, :to => :completed
  end
  
  def short_and_long_name
    "#{name_on_tube} (#{sample_description})"
  end
  
  # override new method to handle naming scheme stuff
  def self.new(attributes=nil)
    sample = super(attributes)

    # see if there's a naming scheme
    begin
      scheme = NamingScheme.find(sample.naming_scheme_id)
    rescue
      return sample
    end
    
    schemed_params = attributes[:schemed_name]
    if(schemed_params.nil?)
      # use default selections if none are provided
      @naming_element_visibility = scheme.default_visibilities
      @text_values = scheme.default_texts
    end
    
    return sample
  end

  def schemed_name=(attributes)
    # clear out old naming scheme records
    sample_terms.each {|t| t.destroy}
    sample_texts.each {|t| t.destroy}

    # create the new records
    self.sample_terms = terms_for(attributes)
    self.sample_texts = texts_for(attributes)
    self.sample_description = naming_scheme.generate_sample_description(attributes)   
  end
  
  def naming_element_visibility
    if(naming_scheme != nil)
      return @naming_element_visibility || naming_scheme.visibilities_from_terms(sample_terms)
    else
      return nil
    end
  end
  
  def text_values
    if(naming_scheme != nil)
      return @text_values || naming_scheme.texts_from_terms(sample_texts)
    else
      return nil
    end
  end
  
  def naming_element_selections
    if(naming_scheme != nil)
      return @naming_element_selections || naming_scheme.element_selections_from_terms(sample_terms)
    else
      return nil
    end
  end  
  
  def validate
    # make sure date/name_on_tube/sample_description combo is unique
    s = Sample.find_by_submission_date_and_name_on_tube_and_sample_description(
        submission_date, name_on_tube, sample_description)
    if( s != nil && s.id != id )
      errors.add("Duplicate submission date/name_on_tube/sample_description")
    end
    
    # look for all the things that infuriate GCOS or SBEAMS:
    # * non-existent sample name
    # * spaces
    # * characters other than underscores and dashes
    if sample_description == nil
      errors.add("Sample description must be supplied")
    elsif sample_description[/\ /] != nil ||
        sample_description[/\+/] != nil ||
        sample_description[/\&/] != nil ||
        sample_description[/\#/] != nil ||
        sample_description[/\(/] != nil ||
        sample_description[/\)/] != nil ||
        sample_description[/\//] != nil ||
        sample_description[/\\/] != nil
      errors.add("Sample description must contain only letters, numbers, underscores and dashes or it")
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
        csv << [
          "Sample ID",
          "Submission Date",
          "Name On Tube",
          "Sample Description",
          "Project",
          "Sample Prep Kit",
          "Reference Genome",
          "Desired Read Length",
          "Alignment Start Position",
          "Alignment End Position",
          "Insert Size",
          "Budget Number",
          "Comment",
          "Naming Scheme"
        ]

        samples = Sample.find( :all, :conditions => {:naming_scheme_id => nil},
          :include => [:reference_genome], :order => "samples.id ASC" )

        for sample in samples
          csv << [ # cel_file,
            sample.id,
            sample.submission_date.to_s,
            sample.name_on_tube,
            sample.sample_description,
            sample.project.name,
            sample.sample_prep_kit.name,
            sample.reference_genome.name,
            sample.desired_read_length,
            sample.alignment_start_position,
            sample.alignment_end_position,
            sample.insert_size,
            sample.budget_number,
            sample.comment || "",
            "None"
          ]
        end
      else
        scheme = NamingScheme.find(:first, :conditions => { :name => naming_scheme })
        
        if(scheme.nil?)
          return nil
        end
        
        # stock headings
        headings = [ #"CEL File",
          "Sample ID",
          "Submission Date",
          "Name On Tube",
          "Sample Description",
          "Project",
          "Sample Prep Kit",
          "Reference Genome",
          "Desired Read Length",
          "Alignment Start Position",
          "Alignment End Position",
          "Insert Size",
          "Budget Number",
          "Comment",
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
          :include => [:reference_genome],
          :order => "samples.id ASC" )

        for sample in samples
          column_values = [ # cel_file,
            sample.id,
            sample.submission_date.to_s,
            sample.name_on_tube,
            sample.sample_description,
            sample.project.name,
            sample.sample_prep_kit.name,
            sample.reference_genome.name,
            sample.desired_read_length,
            sample.alignment_start_position,
            sample.alignment_end_position,
            sample.insert_size,
            sample.budget_number,
            sample.comment || "",
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

  def self.from_csv(csv_file_name, scheme_generation_allowed = false)

    row_number = 0
    header_row = nil

    CSV.open(csv_file_name, 'r') do |row|
      # grab the header row or process sample rows
      if(row_number == 0)
        header_row = row
      else
        begin
          sample = Sample.find(row[0].to_i)
        rescue
          sample = Sample.new
        end
      
        # check to see if this sample should have a naming scheme
        if(row[13] == "None")
          ###########################################
          # non-naming schemed sample
          ###########################################
        
          # there should be 14 cells in each row
          if(row.size != 14)
            return "Wrong number of columns in row #{row_number}. Expected 14"
          end

          if( !sample.new_record? )
            sample.destroy_existing_naming_scheme_info
          end
        
          errors = sample.update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number} of non-naming schemed samples"
          end
        else
          ###########################################
          # naming schemed samples
          ###########################################

          naming_scheme = NamingScheme.find(:first, 
            :conditions => {:name => row[13]})
          # make sure this sample has a naming scheme
          if(naming_scheme.nil?)
            if(scheme_generation_allowed)
              naming_scheme = NamingScheme.create(:name => row[13])
            else
              return "Naming scheme #{row[13]} doesn't exist in row #{row_number}"
            end
          end

          naming_elements =
            naming_scheme.naming_elements.find(:all, :order => "element_order ASC")

          expected_columns = 14 + naming_elements.size
          if(row.size > expected_columns)
            # create new naming elements if that's allowed
            # otherwise return an error message
            if(scheme_generation_allowed)
              if(naming_elements.size > 0)
                current_element_order = naming_elements[-1].element_order + 1
              else
                current_element_order = 1
              end
              (14..header_row.size-1).each do |i|
                NamingElement.create(
                  :name => header_row[i],
                  :element_order => current_element_order,
                  :group_element => true,
                  :optional => true,
                  :naming_scheme_id => naming_scheme.id,
                  :free_text => false,
                  :include_in_sample_description => true,
                  :dependent_element_id => 0)
                current_element_order += 1
              end
              
              # re-populate naming elements array
              naming_elements =
                naming_scheme.naming_elements.find(:all, :order => "element_order ASC")
            else
              return "Wrong number of columns in row #{row_number}. " +
                "Expected #{expected_columns}"
            end
          end

          if( !sample.new_record? )
            sample.destroy_existing_naming_scheme_info
          end
        
          # update the sample attributes
          errors = sample.update_unschemed_columns(row)
          if(errors != "")
            return errors + " in row #{row_number}"
          end

          # create the new naming scheme records
          current_column_index = 14
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
                  if(scheme_generation_allowed)
                    naming_term = NamingTerm.create(
                      :naming_element_id => e.id,
                      :term => row[current_column_index],
                      :abbreviated_term => row[current_column_index],
                      :term_order => 0
                    )
                  else
                    return "Naming term #{row[current_column_index]} doesn't " +
                      "exist for #{e.name} for row #{row_number}"
                  end
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
    reference_genome = ReferenceGenome.find(:first, :conditions => { :name => row[6] })
    if(reference_genome.nil?)
      reference_genome = ReferenceGenome.create(:name => row[6])
    end
    
    project = Project.find(:first, :conditions => { :name => row[4] })
    if(project.nil?)
      return "Project doesn't exist"
    end
    
    sample_prep_kit = SamplePrepKit.find(:first, :conditions => { :name => row[5] })
    if(sample_prep_kit.nil?)
      return "Sample prep kit doesn't exist"
    end

    if(!update_attributes(
          :submission_date => row[1],
          :name_on_tube => row[2],
          :sample_description => row[3],
          :project_id => project.id,
          :sample_prep_kit_id => sample_prep_kit.id,
          :reference_genome_id => reference_genome.id,
          :desired_read_length => row[7],
          :alignment_start_position => row[8],
          :alignment_end_position => row[9],
          :insert_size => row[10],
          :budget_number => row[11],
          :comment => row[12]
        ))
      puts errors.full_messages
      return "Problem updating values for sample id=#{id}: #{errors.full_messages}"
    end
    
    return ""
  end
  
  def terms_for(schemed_params)
    terms = Array.new
    
    count = 1
    for element in naming_scheme.ordered_naming_elements
      depends_upon_element_with_no_selection = false
      depends_upon_element = element.depends_upon_element
      if(depends_upon_element != nil && schemed_params[depends_upon_element.name].to_i <= 0)
        depends_upon_element_with_no_selection = true
      end
      
      # the element must:
      # 1) not be a free text element
      # 2) have a selection
      # 3) not be dependent on an element with no selection
      if( !element.free_text &&
          schemed_params[element.name].to_i > 0 &&
          !depends_upon_element_with_no_selection )
        terms << SampleTerm.new( :sample_id => id, :term_order => count,
          :naming_term_id => NamingTerm.find(schemed_params[element.name]).id )
        count += 1
      end
    end
    
    return terms
  end

  def texts_for(schemed_params)
    texts = Array.new
    
    for element in naming_scheme.ordered_naming_elements
      depends_upon_element_with_no_selection = false
      depends_upon_element = element.depends_upon_element
      if(depends_upon_element != nil && schemed_params[depends_upon_element.name].to_i <= 0)
        depends_upon_element_with_no_selection = true
      end
      
      # the element must:
      # 1) be a free text element
      # 3) not be dependent on an element with no selection
      if( element.free_text &&
          !depends_upon_element_with_no_selection )
        texts << SampleText.new( :sample_id => id, :naming_element_id => element.id,
          :text => schemed_params[element.name] )
      end
    end
    
    return texts
  end
  
  def use_bases_string
    # starting at the beginning
    if(alignment_start_position == 1)
      if(alignment_end_position == desired_read_length)
        return "all"
      else
        return "Y#{alignment_end_position}" + 
               "n#{desired_read_length-alignment_end_position}"
      end
    # or starting later than the beginning, but going to the end
    elsif(alignment_end_position == desired_read_length)
      return "n#{alignment_start_position-1}" +
             "Y#{desired_read_length-alignment_start_position+1}"
    # or in the middle
    else
      return "n#{alignment_start_position-1}" +
             "Y#{alignment_end_position-alignment_start_position}" +
             "n#{desired_read_length-alignment_end_position}"
    end
  end
  
  def summary_hash
    return {
      :id => id,
      :sample_description => sample_description,
      :submission_date => submission_date,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/samples/#{id}"
    }
  end
  
  def detail_hash
    sample_term_array = Array.new
    sample_terms.each do |st|
      sample_term_array << {
        st.naming_term.naming_element.name => st.naming_term.term
      }
    end
    
    sample_text_array = Array.new
    sample_texts.each do |st|
      sample_text_array << {
        st.naming_element.name => st.text
      }
    end
    
    return {
      :id => id,
      :submitted_by => user ? user.full_name : "",
      :name_on_tube => name_on_tube,
      :sample_description => sample_description,
      :project => project.name,
      :submission_date => submission_date,
      :updated_at => updated_at,
      :sample_prep_kit => sample_prep_kit.name,
      :sample_prep_kit_restriction_enzyme => sample_prep_kit.restriction_enzyme,
      :sample_prep_kit_uri => "#{SiteConfig.site_url}/sample_prep_kits/#{sample_prep_kit.id}",
      :insert_size => insert_size,
      :desired_number_of_cycles => desired_read_length,
      :alignment_start_position => alignment_start_position,
      :alignment_end_position => alignment_end_position,
      :reference_genome => {
        :name => reference_genome.name,
        :organism => reference_genome.organism.name
      },
      :status => status,
      :naming_scheme => naming_scheme ? naming_scheme.name : "",
      :budget_number => budget_number,
      :comment => comment,
      :sample_terms => sample_term_array,
      :sample_texts => sample_text_array,
      :flow_cell_lane_uris => flow_cell_lane_ids.
        collect {|x| "#{SiteConfig.site_url}/flow_cell_lanes/#{x}" },
      :project_uri => "#{SiteConfig.site_url}/projects/#{project.id}"
    }
  end
  
  def raw_data_paths
    path_string = ""
    
    flow_cell_lanes.each do |l|
      if(l.raw_data_path != nil)
        path_string += ", " if path_string.length > 0
        path_string += l.raw_data_path
      end
    end
    
    return path_string
  end
  
  def lane_paths=(lane_paths)
    lane_paths.each do |lane_id, path_hash|
      lane = FlowCellLane.find(lane_id)
      lane.raw_data_path = path_hash['raw_data_path']
    end
  end

  def associated_comments
    result = ""

    result = add_comment(result, comment, "sample")

    flow_cells = Array.new
    sequencing_runs = Array.new
    flow_cell_lanes.each do |l|
      result = add_comment(result, l.comment, "lane")
      flow_cells << l.flow_cell
      l.flow_cell.sequencing_runs.each do |s|
        sequencing_runs << s
      end
    end

    flow_cells.uniq.each do |f|
      result = add_comment(result, f.comment, "flow cell")
    end

    sequencing_runs.uniq.each do |s|
      result = add_comment(result, s.comment, "sequencing")
    end

    if(result.length > 0)
      return result
    else
      return "No comments"
    end
  end

  def user
    if(submitted_by_id != nil)
      return User.find(submitted_by_id)
    else
      return nil
    end
  end

  def self.accessible_to_user(user)
    samples = Sample.find(:all, 
      :include => 'project',
      :conditions => [ "projects.lab_group_id IN (?) AND control = ?",
        user.get_lab_group_ids, false ],
      :order => "submission_date DESC, samples.id ASC")
  end

  def self.browse_by(samples, categories, search_prefix = "")
    return nil if categories.nil?

    category = categories.shift

    value = Array.new
    case category
    when "project"
      samples.group_by(&:project).each do |project, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "project_id=#{project.id}")
        value << {
          :name => project.name,
          :number => sub_samples.size,
          :search_string => sub_prefix,
          :children => Sample.browse_by(sub_samples, categories.dup, sub_prefix)
        }
      end
    when "submitter"
      samples.group_by(&:submitted_by_id).each do |user_id, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "submitted_by_id=#{user_id}")

        users_by_id = User.all_by_id
        value << {
          :name => users_by_id[user_id].full_name,
          :number => sub_samples.size,
          :search_string => sub_prefix,
          :children => Sample.browse_by(sub_samples, categories.dup, sub_prefix)
        }
      end
    when /naming_element-(\d+)/
      element = NamingElement.find($1)
      
      element.naming_terms.each do |term|
        samples_for_term = Sample.find(:all, :include => :sample_terms,
                                       :conditions => ["sample_terms.naming_term_id = ?", term.id])
        sub_samples = samples & samples_for_term
        sub_prefix = combine_search(search_prefix, "naming_term_id=#{term.id}")
        
        next if sub_samples.size == 0

        value << {
          :name => term.term,
          :number => sub_samples.size,
          :search_string => sub_prefix,
          :children => Sample.browse_by(sub_samples, categories.dup, sub_prefix)
        }
      end
    else
      value = nil
    end

    return value
  end

  def self.find_by_sanitized_conditions(conditions)
    accepted_keys = {
      'project_id' => 'project_id',
      'submitted_by_id' => 'submitted_by_id',
      'naming_term_id' => 'sample_terms.naming_term_id'
    }

    sanitized_conditions = Hash.new

    conditions.each do |key, value|
      if accepted_keys.include?(key)
        sanitized_conditions[ accepted_keys[key] ] = value
      end
    end

    return Sample.find(:all, :include => :sample_terms, :conditions => sanitized_conditions)
  end

  def self.browsing_categories
    categories = [
      ['Project', 'project'],
      ['Submitter', 'submitter'],
    ]

    NamingScheme.find(:all, :order => "name ASC").each do |scheme|
      scheme.naming_elements.find(:all, :order => "name ASC").each do |element|
        categories << ["#{scheme.name}: #{element.name}", "naming_element-#{element.id}"]
      end
    end

    return categories
  end

private

  def add_comment(base, comment, type)
    if(comment && comment.length > 0)
      base += ", " if base.length > 0
      base += "#{type}: #{comment}" 
    end

    return base
  end

  def self.combine_search(base_string, added_string)
    if(base_string.length == 0)
      return added_string
    else
      return "#{base_string}&#{added_string}"
    end
  end

end
