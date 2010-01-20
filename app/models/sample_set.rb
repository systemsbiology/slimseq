class SampleSet < ActiveRecord::BaseWithoutTable
  column :submission_date, :date
  column :number_of_samples, :string
  column :project_id, :integer
  column :naming_scheme_id, :integer
  column :sample_prep_kit_id, :integer
  column :budget_number, :string
  column :reference_genome_id, :integer
  column :desired_read_length, :integer
  column :insert_size, :integer
  column :alignment_start_position, :integer, :default => 1
  column :alignment_end_position, :integer
  column :eland_parameter_set_id, :integer

  validates_numericality_of :number_of_samples, :greater_than_or_equal_to => 1
  validates_numericality_of :insert_size
  validates_presence_of :budget_number, :reference_genome_id,
    :sample_prep_kit_id, :desired_read_length, :project_id
  validates_numericality_of :alignment_start_position, :greater_than_or_equal_to => 1
  validates_numericality_of :alignment_end_position, :greater_than_or_equal_to => 1
  
  has_many :samples
  
  belongs_to :naming_scheme

  attr_accessor :errors
  
  def self.new(attributes=nil)
    samples_hash = attributes.delete("samples")
    submitted_by_login = attributes.delete("submitted_by")

    sample_set = super(attributes)
    sample_set.errors = Array.new

    # this should set the initial end position
    if(sample_set.alignment_end_position.nil?)
      sample_set.alignment_end_position = 36
    end
    
    # handle cases where a samples hash is provided
    if(samples_hash)
      begin
        samples_hash.each do |sample_hash|
          begin
            user = User.find_by_login(submitted_by_login)
          rescue ActiveRecord::RecordNotFound
            raise "The user login specified by 'submitted_by' was not found"
          end

          sample = Sample.new(attributes.merge( {
            :name_on_tube => sample_hash["name_on_tube"],
            :sample_description => sample_hash["sample_description"] || "",
            :submitted_by_id => user.id,
            :submission_date => sample_hash["submission_date"] || Date.today
          } ))

          begin
            naming_scheme = NamingScheme.find(attributes["naming_scheme_id"])
          rescue ActiveRecord::RecordNotFound => e
            raise "The sample information seems to include meta data using a naming scheme, " +
              "but the naming scheme specified is invalid"
          end

          term_list = Array.new
          sample_hash.keys.grep(/^[A-Z]/).each do |element_name|
            naming_element = naming_scheme.naming_elements.find_by_name(element_name)
            raise "Specified naming element #{element_name} wasn't found for the naming " +
              "scheme #{naming_scheme.name}" unless(naming_element)

            if(naming_element.free_text)
              sample.sample_texts.build(:text => sample_hash[element_name],
                                        :naming_element_id => naming_element.id)
              term_list << sample_hash[element_name]
            else
              naming_term = naming_element.naming_terms.find_by_term(sample_hash[element_name])
              raise "The specified term is not in the controller vocabulary for #{element_name}" unless naming_term
              sample.sample_terms.build(:naming_term => naming_term)

              term_list << naming_term.abbreviated_term
            end
          end
          sample.sample_description = term_list.join("_") unless term_list.empty?

          raise "Sample parameters are invalid: #{sample.errors}" unless sample.valid?
          sample_set.samples << sample
        end
      rescue Exception => e
        sample_set.errors << e.message
      end
    end

    return sample_set
  end

  def valid?
    if errors.empty?
      return true
    else
      return false
    end
  end

  def save
    return false unless valid?

    samples.each do |sample|
      sample.save
    end
  end

  def project
    return Project.find(project_id)
  end
end
