#class SampleSet < ActiveRecord::BaseWithoutTable
class SampleSet < ActiveRecord::Base
  # use validatable gem since we're validating attributes that aren't fields
  # in the sample_sets table (because they're transient)
  include Validatable

  attr_accessor :submission_date
  attr_accessor :number_of_samples
  attr_accessor :project_id
  attr_accessor :naming_scheme_id
  attr_accessor :sample_prep_kit_id
  attr_accessor :budget_number
  attr_accessor :reference_genome_id
  attr_accessor :desired_read_length
  attr_accessor :insert_size
  attr_accessor :alignment_start_position
  attr_accessor :alignment_end_position
  attr_accessor :eland_parameter_set_id
  attr_accessor :submitted_by
  attr_accessor :multiplex_number
  attr_accessor :submission_step

  has_many :sample_mixtures

  validates_presence_of :budget_number, :reference_genome_id,
    :sample_prep_kit_id, :desired_read_length, :project_id, :eland_parameter_set_id
  validates_presence_of :number_of_samples, :if => lambda { sample_mixtures.nil? || sample_mixtures.empty? }
  validates_numericality_of :alignment_start_position
  validates_numericality_of :alignment_end_position
  validates_true_for :alignment_start_position,
    :logic => lambda { alignment_start_position.to_i > 0 }
  validates_true_for :alignment_end_position,
    :logic => lambda { alignment_start_position.to_i > 0 }
  
  def self.new(attributes=nil)
    mixture_attributes = attributes.delete("sample_mixtures_attributes") || attributes.delete("sample_mixtures") if attributes

    parse_multi_field_date(attributes)
    sample_set = super

    # build empty sample mixtures and samples
    # these will be replaced if sample mixture attributes have been provided
    sample_set.number_of_samples.to_i.times do
      mixture = sample_set.sample_mixtures.build
      sample_set.multiplex_number.to_i.times do
        mixture.samples.build
      end
    end
    sample_set.submission_step = 1

    normalized_mixture_attributes = normalize_mixture_attributes(mixture_attributes)
    sample_set.load_mixture_attributes(normalized_mixture_attributes)

    return sample_set
  end

  # needed this to get fields_for to work in the view
  def sample_mixtures_attributes=(attributes)
  end

  def load_mixture_attributes(attributes)
    return unless attributes

    self.sample_mixtures.clear

    attributes.each do |mixture_attributes|
      samples_attributes = mixture_attributes.delete("samples")

      mixture_attributes.merge! mixture_specific_attributes
      mixture = sample_mixtures.build(mixture_attributes)

      if samples_attributes
        samples_attributes.each do |sample_attributes|
          sample_attributes.merge! sample_specific_attributes
          mixture.samples.build(sample_attributes)
        end
      end
    end

    self.submission_step = 2

    return sample_mixtures
  end

  def mixture_specific_attributes
    return attribute_subset([
      "submission_date", "project_id", "sample_prep_kit_id", "budget_number",
      "desired_read_length", "alignment_start_position", "alignment_end_position",
      "eland_parameter_set_id", "submitted_by"
    ])
  end

  def sample_specific_attributes
    return attribute_subset([
      "naming_scheme_id", "reference_genome_id", "insert_size"
    ])
  end

  def attribute_subset(keys)
    Hash[
      keys.collect{|key| [key, send(key)]}
    ]
  end

  def valid?
    return false unless errors.empty?

    if submission_step == 2
      sample_mixtures.each do |mixture|
        return false unless mixture.valid?
      end
    end

    super
  end

  def save(perform_validation = true)
    return false if perform_validation && !valid?

    super

    # send notification email
    Notifier.deliver_sample_submission_notification(sample_mixtures, project.lab_group)

    return true
  end

  def project
    return Project.find(project_id)
  end

  def naming_scheme
    NamingScheme.find_by_id(naming_scheme_id)
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
          :postback_uri => sample_hash["postback_uri"],
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
        :naming_scheme_id => naming_scheme_id,
        :reference_genome_id => reference_genome_id,
        :insert_size => insert_size,
        :sample_set => self
      )
    end
  end

  private

  def self.normalize_mixture_attributes(attributes)
    return nil unless attributes

    # if mixtures are given as key/value pairs, normalization is needed
    if attributes.respond_to?(:keys)
      attributes = hash_values_sorted_by_keys(attributes)
    end

    attributes.each_index do |i|
      samples = attributes[i].delete("samples_attributes")
      next unless samples

      if samples.respond_to?(:keys)
        samples = hash_values_sorted_by_keys(samples)

        samples.each_index do |j|
          # handle 'sample_key' being synonymous for 'sample_description'
          sample_key = samples[j].delete("sample_key")
          samples[j]["sample_description"] = sample_key if sample_key
        end
      end

      attributes[i]["samples"] = samples
    end

    return attributes
  end

  def self.hash_values_sorted_by_keys(hash)
    sorted = Array.new

    hash.sort.each do |key, value|
      sorted << value
    end

    return sorted
  end

  def self.parse_multi_field_date(attributes)
    return unless attributes

    # assume multi-field if year field is present
    if attributes["submission_date(1i)"]
      attributes["submission_date"] = Date.new(
        attributes.delete("submission_date(1i)").to_i,
        attributes.delete("submission_date(2i)").to_i,
        attributes.delete("submission_date(3i)").to_i
      )
    end
  end
end
