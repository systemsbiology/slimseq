class Sample < ActiveRecord::Base
  require 'spreadsheet/excel'
  require 'parseexcel'
  require 'csv'
  include Spreadsheet
  
  belongs_to :organism
  belongs_to :naming_scheme
  belongs_to :reference_genome
  belongs_to :experiment
  belongs_to :multiplex_code

  belongs_to :sample_mixture
  
  has_many :sample_terms, :dependent => :destroy
  has_many :sample_texts, :dependent => :destroy

  validates_presence_of :sample_description, :reference_genome_id
  
  attr_accessor :schemed_name
  
  # temporarily associates with a sample set, which doesn't get stored in db
  attr_accessor :sample_set_id
  belongs_to :sample_set

  # provide convenience methods to get at attributes of parent sample mixture
  [:project, :submitted_by_id, :submission_date, :sample_prep_kit, :status].each do |attribute|
    define_method(attribute) { sample_mixture.send(attribute) }
  end

  # override new method to handle naming scheme stuff
  def self.new(attributes=nil)
    schemed_params = attributes.delete("schemed_name") if attributes

    sample = super
    sample.schemed_name = schemed_params
    
    return sample
  end

  def schemed_name=(attributes)
    return unless naming_scheme

    destroy_existing_naming_scheme_info

    if attributes
      # create the new records
      build_terms(attributes)
      build_texts(attributes)
      generate_schemed_sample_description
    else
      @naming_element_visibility = naming_scheme.default_visibilities
      @text_values = naming_scheme.default_texts
    end
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
    # Don't allow:
    # * non-existent sample name
    # * spaces
    # * characters other than underscores and dashes
    if sample_description == nil
      errors.add("Description must be supplied")
    elsif sample_description[/\ /] != nil ||
        sample_description[/\+/] != nil ||
        sample_description[/\&/] != nil ||
        sample_description[/\#/] != nil ||
        sample_description[/\(/] != nil ||
        sample_description[/\)/] != nil ||
        sample_description[/\//] != nil ||
        sample_description[/\\/] != nil
      errors.add("Description must contain only letters, numbers, underscores and dashes or it")
    end
  end

#  def self.to_csv(naming_scheme = "")
#    ###########################################
#    # set up spreadsheet
#    ###########################################
#    
#    csv_file_name = "#{RAILS_ROOT}/tmp/csv/samples_" +
#      "#{Date.today.to_s}-#{naming_scheme}.csv"
#    
#    csv_file = File.open(csv_file_name, 'wb')
#    CSV::Writer.generate(csv_file) do |csv|
#      if(naming_scheme == "")
#        csv << [
#          "Sample ID",
#          "Submission Date",
#          "Name On Tube",
#          "Sample Description",
#          "Project",
#          "Sample Prep Kit",
#          "Reference Genome",
#          "Desired Read Length",
#          "Alignment Start Position",
#          "Alignment End Position",
#          "Insert Size",
#          "Budget Number",
#          "Comment",
#          "Naming Scheme"
#        ]
#
#        samples = Sample.find( :all,
#          :conditions => "naming_scheme_id = 0 OR naming_scheme_id IS NULL",
#          :include => [:reference_genome], :order => "samples.id ASC" )
#
#        for sample in samples
#          csv << [ # cel_file,
#            sample.id,
#            sample.submission_date.to_s,
#            sample.name_on_tube,
#            sample.sample_description,
#            sample.project.name,
#            sample.sample_prep_kit.name,
#            sample.reference_genome.name,
#            sample.desired_read_length,
#            sample.alignment_start_position,
#            sample.alignment_end_position,
#            sample.insert_size,
#            sample.budget_number,
#            sample.comment || "",
#            "None"
#          ]
#        end
#      else
#        scheme = NamingScheme.find(:first, :conditions => { :name => naming_scheme })
#        
#        if(scheme.nil?)
#          return nil
#        end
#        
#        # stock headings
#        headings = [ #"CEL File",
#          "Sample ID",
#          "Submission Date",
#          "Name On Tube",
#          "Sample Description",
#          "Project",
#          "Sample Prep Kit",
#          "Reference Genome",
#          "Desired Read Length",
#          "Alignment Start Position",
#          "Alignment End Position",
#          "Insert Size",
#          "Budget Number",
#          "Comment",
#          "Naming Scheme"
#        ]
#
#        # headings for naming elements
#        naming_elements = 
#          scheme.naming_elements.find(:all, :order => "element_order ASC")
#        naming_elements.each do |e|
#          headings << e.name
#        end
#
#        csv << headings
#
#        samples = Sample.find( :all, 
#          :conditions => {:naming_scheme_id => scheme.id},
#          :include => [:reference_genome],
#          :order => "samples.id ASC" )
#
#        for sample in samples
#          column_values = [ # cel_file,
#            sample.id,
#            sample.submission_date.to_s,
#            sample.name_on_tube,
#            sample.sample_description,
#            sample.project.name,
#            sample.sample_prep_kit.name,
#            sample.reference_genome.name,
#            sample.desired_read_length,
#            sample.alignment_start_position,
#            sample.alignment_end_position,
#            sample.insert_size,
#            sample.budget_number,
#            sample.comment || "",
#            sample.naming_scheme.name
#          ]
#          # values for naming elements
#          naming_elements.each do |e|
#            value = ""
#            if(e.free_text == true)
#              sample_text = SampleText.find(:first, 
#                :conditions => {:sample_id => sample.id,
#                  :naming_element_id => e.id})
#              if(sample_text != nil)
#                value = sample_text.text
#              end
#            else
#              sample_term = SampleTerm.find(:first,
#                :include => :naming_term,
#                :conditions => ["sample_id = ? AND naming_terms.naming_element_id = ?",
#                  sample.id, e.id] )
#              if(sample_term != nil)
#                value = sample_term.naming_term.term
#              end
#            end
#            column_values << value
#          end
#
#          csv << column_values
#        end
#      end    
#    end
#  
#    csv_file.close
#     
#    return csv_file_name
#  end
#
#  def self.from_csv(csv_file_name, scheme_generation_allowed = false)
#
#    row_number = 0
#    header_row = nil
#
#    CSV.open(csv_file_name, 'r') do |row|
#      # grab the header row or process sample rows
#      if(row_number == 0)
#        header_row = row
#      else
#        begin
#          sample = Sample.find(row[0].to_i)
#        rescue
#          sample = Sample.new
#        end
#      
#        # check to see if this sample should have a naming scheme
#        if(row[13] == "None")
#          ###########################################
#          # non-naming schemed sample
#          ###########################################
#        
#          # there should be 14 cells in each row
#          if(row.size != 14)
#            return "Wrong number of columns in row #{row_number}. Expected 14"
#          end
#
#          if( !sample.new_record? )
#            sample.destroy_existing_naming_scheme_info
#          end
#        
#          errors = sample.update_unschemed_columns(row)
#          if(errors != "")
#            return errors + " in row #{row_number} of non-naming schemed samples"
#          end
#        else
#          ###########################################
#          # naming schemed samples
#          ###########################################
#
#          naming_scheme = NamingScheme.find(:first, 
#            :conditions => {:name => row[13]})
#          # make sure this sample has a naming scheme
#          if(naming_scheme.nil?)
#            if(scheme_generation_allowed)
#              naming_scheme = NamingScheme.create(:name => row[13])
#            else
#              return "Naming scheme #{row[13]} doesn't exist in row #{row_number}"
#            end
#          end
#
#          naming_elements =
#            naming_scheme.naming_elements.find(:all, :order => "element_order ASC")
#
#          expected_columns = 14 + naming_elements.size
#          if(row.size > expected_columns)
#            # create new naming elements if that's allowed
#            # otherwise return an error message
#            if(scheme_generation_allowed)
#              if(naming_elements.size > 0)
#                current_element_order = naming_elements[-1].element_order + 1
#              else
#                current_element_order = 1
#              end
#              (14..header_row.size-1).each do |i|
#                NamingElement.create(
#                  :name => header_row[i],
#                  :element_order => current_element_order,
#                  :group_element => true,
#                  :optional => true,
#                  :naming_scheme_id => naming_scheme.id,
#                  :free_text => false,
#                  :include_in_sample_description => true,
#                  :dependent_element_id => 0)
#                current_element_order += 1
#              end
#              
#              # re-populate naming elements array
#              naming_elements =
#                naming_scheme.naming_elements.find(:all, :order => "element_order ASC")
#            else
#              return "Wrong number of columns in row #{row_number}. " +
#                "Expected #{expected_columns}"
#            end
#          end
#
#          if( !sample.new_record? )
#            sample.destroy_existing_naming_scheme_info
#          end
#        
#          # update the sample attributes
#          errors = sample.update_unschemed_columns(row)
#          if(errors != "")
#            return errors + " in row #{row_number}"
#          end
#
#          # create the new naming scheme records
#          current_column_index = 14
#          naming_elements.each do |e|
#            # do nothing if there's nothing in the cell
#            if(row[current_column_index] != nil)
#              if(e.free_text == true)
#                sample_text = SampleText.new(
#                  :sample_id => sample.id,
#                  :naming_element_id => e.id,
#                  :text => row[current_column_index]
#                )
#                if(!sample_text.save)
#                  return "Unable to create #{e.name} for row #{row_number}"
#                end
#              else
#                naming_term = NamingTerm.find(:first, 
#                  :conditions => ["naming_element_id = ? AND " +
#                    "(term = ? OR abbreviated_term = ?)",
#                    e.id,
#                    row[current_column_index],
#                    row[current_column_index] ])
#                # if naming term wasn't found,
#                # match leading 0's if there are any
#                if(naming_term.nil?)
#                  naming_term = NamingTerm.find(:first, 
#                    :conditions => ["naming_element_id = ? AND " +
#                      "(term REGEXP ? OR abbreviated_term REGEXP ?)",
#                      e.id,
#                      "0*" + row[current_column_index],
#                      "0*" + row[current_column_index] ])
#                end
#                if(naming_term.nil?)
#                  if(scheme_generation_allowed)
#                    naming_term = NamingTerm.create(
#                      :naming_element_id => e.id,
#                      :term => row[current_column_index],
#                      :abbreviated_term => row[current_column_index],
#                      :term_order => 0
#                    )
#                  else
#                    return "Naming term #{row[current_column_index]} doesn't " +
#                      "exist for #{e.name} for row #{row_number}"
#                  end
#                end
#                sample_term = SampleTerm.new(
#                  :sample_id => sample.id,
#                  :naming_term_id => naming_term.id
#                )
#                if(!sample_term.save)
#                  return "Unable to create #{e.name} for row #{row_number}"
#                end
#              end
#            end
#            current_column_index += 1
#          end
#          sample.update_attributes(:naming_scheme_id => naming_scheme.id)
#        end
#      end      
#      row_number += 1
#    end
#
#    return ""
#  end

  def destroy_existing_naming_scheme_info
    sample_terms.clear
    sample_texts.clear
  end

#  def update_unschemed_columns(row)
#    reference_genome = ReferenceGenome.find(:first, :conditions => { :name => row[6] })
#    if(reference_genome.nil?)
#      reference_genome = ReferenceGenome.create(:name => row[6])
#    end
#    
#    project = Project.find(:first, :conditions => { :name => row[4] })
#    if(project.nil?)
#      return "Project doesn't exist"
#    end
#    
#    sample_prep_kit = SamplePrepKit.find(:first, :conditions => { :name => row[5] })
#    if(sample_prep_kit.nil?)
#      return "Sample prep kit doesn't exist"
#    end
#
#    if(!update_attributes(
#          :submission_date => row[1],
#          :name_on_tube => row[2],
#          :sample_description => row[3],
#          :project_id => project.id,
#          :sample_prep_kit_id => sample_prep_kit.id,
#          :reference_genome_id => reference_genome.id,
#          :desired_read_length => row[7],
#          :alignment_start_position => row[8],
#          :alignment_end_position => row[9],
#          :insert_size => row[10],
#          :budget_number => row[11],
#          :comment => row[12]
#        ))
#      puts errors.full_messages
#      return "Problem updating values for sample id=#{id}: #{errors.full_messages}"
#    end
#    
#    return ""
#  end
  
  def build_terms(schemed_params)
    count = 1

    for element in naming_scheme.ordered_naming_elements
      # the element must not be:
      # 1) a free text element
      # 2) dependent on an element with no selection
      depends_upon_element = element.depends_upon_element
      next if element.free_text
      next if depends_upon_element != nil && schemed_params[depends_upon_element.name].to_i <= 0
      
      term_selection = schemed_params[element.name]

      naming_term = element.naming_terms.find_by_term(term_selection) ||
        element.naming_terms.find_by_id(term_selection)
      next unless naming_term

      self.sample_terms.build(:term_order => count, :naming_term => naming_term)

      count += 1
    end
  end

  def build_texts(schemed_params)
    for element in naming_scheme.ordered_naming_elements
      # the element must not be:
      # 1) a free text element
      # 2) dependent on an element with no selection
      next unless element.free_text
      depends_upon_element = element.depends_upon_element
      next if depends_upon_element != nil && schemed_params[depends_upon_element.name].to_i <= 0

      sample_texts.build(:naming_element_id => element.id, :text => schemed_params[element.name] )
    end
  end
  
  def generate_schemed_sample_description
    description = Array.new

    for element in naming_scheme.ordered_naming_elements
      term = sample_terms.select{|term| term.naming_term.naming_element_id == element.id}.first
      text = sample_texts.select{|text| text.naming_element_id == element.id}.first
      #term = sample_terms.find(:first, :include => :naming_term,
      #  :conditions => {:naming_terms => {:naming_element_id => element.id}})
      #text = sample_texts.find(:first, :include => :naming_element,
      #  :conditions => {:naming_element_id => element.id})

      if term
        description << term.naming_term.abbreviated_term
      elsif text
        description << text.text
      else
        description << ""
      end
    end

    self.sample_description = description.join "_"
  end

  def summary_hash
    return {
      :id => id,
      :sample_description => sample_description,
      :submission_date => sample_mixture.submission_date,
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
      :submitted_by => sample_mixture.user ? sample_mixture.user.full_name : "",
      :name_on_tube => sample_mixture.name_on_tube,
      :sample_description => sample_description,
      :project => sample_mixture.project.name,
      :submission_date => sample_mixture.submission_date,
      :updated_at => updated_at,
      :sample_prep_kit => sample_mixture.sample_prep_kit.name,
      :sample_prep_kit_restriction_enzyme => sample_mixture.sample_prep_kit.restriction_enzyme,
      :sample_prep_kit_uri => "#{SiteConfig.site_url}/sample_prep_kits/#{sample_mixture.sample_prep_kit.id}",
      :insert_size => insert_size,
      :desired_number_of_cycles => sample_mixture.desired_read_length,
      :alignment_start_position => sample_mixture.alignment_start_position,
      :alignment_end_position => sample_mixture.alignment_end_position,
      :reference_genome_id => reference_genome_id,
      :reference_genome => {
        :name => reference_genome.name,
        :organism => reference_genome.organism.name
      },
      :status => sample_mixture.status,
      :naming_scheme => naming_scheme ? naming_scheme.name : "",
      :budget_number => sample_mixture.budget_number,
      :comment => sample_mixture.comment,
      :sample_terms => sample_term_array,
      :sample_texts => sample_text_array,
      :flow_cell_lane_uris => sample_mixture.flow_cell_lane_ids.
        collect {|x| "#{SiteConfig.site_url}/flow_cell_lanes/#{x}" },
      :project_uri => "#{SiteConfig.site_url}/projects/#{sample_mixture.project.id}"
    }
  end

  def tree_hash
    site_url=ENV['RAILS_RELATIVE_URL_ROOT']
    { :id=> "s_#{id}",
      :text => sample_mixture.name_on_tube,
      :href => "#{site_url}/samples/#{id}/edit",
      :leaf => true
    }
  end   
  
  def raw_data_paths
    path_string = ""
    
    sample_mixture.flow_cell_lanes.each do |l|
      if(l.raw_data_path != nil)
        path_string += ", " if path_string.length > 0
        path_string += l.raw_data_path
      end
    end
    
    return path_string
  end
  
  def user
    sample_mixture.user
  end

  def self.accessible_to_user(user)
    samples = Sample.find(:all, 
      :include => {:sample_mixture => :project},
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
        value << branch_hash(project.name, sub_samples, sub_prefix, categories)
      end
    when "submitter"
      samples.group_by(&:submitted_by_id).each do |user_id, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "submitted_by_id=#{user_id}")

        users_by_id = User.all_by_id
        value << branch_hash(users_by_id[user_id].full_name, sub_samples, sub_prefix, categories)
      end
    when "submission_date"
      samples.group_by(&:submission_date).each do |submission_date, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "submission_date=#{submission_date}")

        value << branch_hash(submission_date, sub_samples, sub_prefix, categories)
      end
    when "sample_prep_kit"
      samples.group_by(&:sample_prep_kit).each do |sample_prep_kit, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "sample_prep_kit_id=#{sample_prep_kit.id}")

        value << branch_hash(sample_prep_kit.name, sub_samples, sub_prefix, categories)
      end
    when "insert_size"
      samples.group_by(&:insert_size).each do |insert_size, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "insert_size=#{insert_size}")

        value << branch_hash(insert_size, sub_samples, sub_prefix, categories)
      end
    when "reference_genome"
      samples.group_by(&:reference_genome).each do |reference_genome, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "reference_genome_id=#{reference_genome.id}")

        value << branch_hash(reference_genome.name, sub_samples, sub_prefix, categories)
      end
    when "organism"
      Organism.find(:all).each do |organism|
        organism_samples = Array.new
        organism.reference_genomes.each do |genome|
          organism_samples.concat(genome.samples)
        end
        sub_samples = samples & organism_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "organism_id=#{organism.id}")

        value << branch_hash(organism.name, sub_samples, sub_prefix, categories)
      end
    when "status"
      samples.group_by(&:status).each do |status, sub_samples|
        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "status=#{status}")

        value << branch_hash(status, sub_samples, sub_prefix, categories)
      end
    when "naming_scheme"
      samples.group_by(&:naming_scheme).each do |naming_scheme, sub_samples|
        next if sub_samples.size == 0

        if(naming_scheme.nil?)
          sub_prefix = combine_search(search_prefix, 'naming_scheme_id=')
          value << branch_hash("None", sub_samples, sub_prefix, categories)
        else
          sub_prefix = combine_search(search_prefix, "naming_scheme_id=#{naming_scheme.id}")
          value << branch_hash(naming_scheme.name, sub_samples, sub_prefix, categories)
        end
      end
    when "flow_cell"
      FlowCell.find(:all).each do |flow_cell|
        flow_cell_samples = Array.new
        flow_cell.flow_cell_lanes.each do |lane|
          flow_cell_samples.concat(lane.sample_mixture.samples)
        end
        sub_samples = samples & flow_cell_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "flow_cell_id=#{flow_cell.id}")

        value << branch_hash(flow_cell.name, sub_samples, sub_prefix, categories)
      end
    when "lab_group"
      LabGroup.find(:all).each do |lab_group|
        lab_group_samples = Array.new
        Project.for_lab_group(lab_group).each do |project|
          lab_group_samples.concat(project.sample_mixtures.collect{|m| m.samples})
        end
        lab_group_samples.flatten!
        sub_samples = samples & lab_group_samples

        next if sub_samples.size == 0

        sub_prefix = combine_search(search_prefix, "lab_group_id=#{lab_group.id}")

        value << branch_hash(lab_group.name, sub_samples, sub_prefix, categories)
      end
    when /naming_element-(\d+)/
      element = NamingElement.find($1)
      
      element.naming_terms.each do |term|
        samples_for_term = Sample.find(:all, :include => :sample_terms,
                                       :conditions => ["sample_terms.naming_term_id = ?", term.id])
        sub_samples = samples & samples_for_term
        sub_prefix = combine_search(search_prefix, "naming_term_id=#{term.id}")
        
        next if sub_samples.size == 0

        value << branch_hash(term.term, sub_samples, sub_prefix, categories)
      end
    else
      value = nil
    end

    return value
  end

  def self.combine_search(base_string, added_string)
    added_string.match(/\A(.*?)=(.*?)\Z/)
    key = $1
    value = $2

    if(base_string.length == 0)
      return added_string
    elsif( base_string.match(/#{key}=(\d+)/) )
      return base_string.gsub(/#{key}=(\d+)/, "#{key}=#{$1},#{value}")
    else
      return "#{base_string}&#{added_string}"
    end
  end

  def self.branch_hash(name, samples, prefix, categories)
    return {
      :name => name,
      :number => samples.size,
      :search_string => prefix,
      :children => Sample.browse_by(samples, categories.dup, prefix)
    }
  end

end
