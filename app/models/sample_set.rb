class SampleSet < ActiveRecord::BaseWithoutTable
  column :submission_date, :date
  column :number_of_samples, :integer
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
  column :submitted_by, :string

  validates_presence_of :budget_number, :reference_genome_id,
    :sample_prep_kit_id, :desired_read_length, :project_id, :eland_parameter_set_id
  validates_numericality_of :alignment_start_position, :greater_than_or_equal_to => 1
  validates_numericality_of :alignment_end_position, :greater_than_or_equal_to => 1
  
  has_many :samples, :validate => false
  
  belongs_to :naming_scheme

  def self.new(attributes=nil, sample_form_hash = nil)
    sample_api_hash = attributes.delete("samples") if attributes
    number_of_samples = attributes["number_of_samples"] if attributes

    sample_set = super(attributes)

    # set the end position unless already specified
    sample_set.alignment_end_position = 36 unless sample_set.alignment_end_position
    
    if sample_api_hash
      sample_set.load_sample_api_hash(sample_api_hash, attributes)
    elsif sample_form_hash
      sample_set.load_sample_form_hash(sample_form_hash)
    elsif number_of_samples
      sample_set.initialize_samples(number_of_samples, attributes)
    end

    return sample_set
  end

  def valid?
    return false unless errors.empty?

    super
  end

  def save
    return false unless valid?

    samples.each do |sample|
      sample.save!
    end

    # send notification email
    Notifier.deliver_sample_submission_notification(samples, project.lab_group)
  end

  def project
    return Project.find(project_id)
  end

  def load_sample_api_hash(sample_api_hash, attributes)
    submitted_by = attributes.delete("submitted_by")

    begin
      sample_api_hash.each do |sample_hash|
        begin
          user = User.find_by_login(submitted_by)
        rescue ActiveRecord::RecordNotFound
          raise "The user login specified by 'submitted_by' was not found"
        end

        sample = Sample.new(attributes.merge( {
          :name_on_tube => sample_hash["name_on_tube"],
          :sample_description => sample_hash["sample_description"] || sample_hash["sample_key"] || "",
          :submitted_by_id => user.id,
          :submission_date => sample_hash["submission_date"] || Date.today
        } ))

        begin
          naming_scheme = NamingScheme.find(attributes["naming_scheme_id"])
        rescue ActiveRecord::RecordNotFound => e
          # do nothing
        end

        term_list = Array.new
        sample_hash.keys.grep(/^[A-Z]/).each do |element_name|
          raise "The sample information seems to include meta data using a naming scheme, " +
            "but the naming scheme specified is invalid" unless naming_scheme
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

        error_text = (sample.errors.collect {|e| e.to_s}).join(", ") unless sample.valid?
        raise "Sample parameters are invalid: #{error_text}" if error_text
        samples << sample
      end
    rescue Exception => e
      errors.add_to_base(e.message)
    end
  end

  def load_sample_form_hash(sample_form_hash)
    sample_form_hash.each_value do |sample_attributes|
      samples << Sample.new(sample_attributes)
    end
  end

  def initialize_samples(number, attributes)
    errors.add(:number_of_samples, "must be provided") unless number && number != ""

    submitted_by = attributes.delete("submitted_by")
    user = User.find_by_login(submitted_by)

    number.to_i.times do
      samples << Sample.new(
        :submission_date => submission_date,
        :project_id => project_id,
        :naming_scheme_id => naming_scheme_id,
        :sample_prep_kit_id => sample_prep_kit_id,
        :reference_genome_id => reference_genome_id,
        :desired_read_length => desired_read_length,
        :alignment_start_position => alignment_start_position,
        :alignment_end_position => alignment_end_position,
        :eland_parameter_set_id => eland_parameter_set_id,
        :insert_size => insert_size,
        :budget_number => budget_number,
        :submitted_by_id => user.id,
        :sample_set => self
      )
    end
  end
end
