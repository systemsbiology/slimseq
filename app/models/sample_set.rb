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
    deprecated_sample_attributes = attributes.delete("samples") if attributes

    parse_multi_field_date(attributes)
    sample_set = super

    sample_set.alignment_start_position ||= 1
    sample_set.submission_date ||= Date.today

    # build empty sample mixtures and samples
    # these will be replaced if sample mixture attributes have been provided
    sample_set.build_blank_mixtures_and_samples
    sample_set.submission_step = 1

    normalized_mixture_attributes = normalize_mixture_attributes(mixture_attributes, deprecated_sample_attributes)
    sample_set.load_mixture_attributes(normalized_mixture_attributes)

    return sample_set
  end

  # needed this to get fields_for to work in the view
  def sample_mixtures_attributes=(attributes)
  end

  def build_blank_mixtures_and_samples
    number_of_samples.to_i.times do
      mixture = sample_mixtures.build(mixture_specific_attributes)
      multiplex_number.to_i.times do
        mixture.samples.build(sample_specific_attributes)
      end
    end
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

  def valid?
    if submission_step == 2
      # manually collect errors across sample_mixtures and samples, rather than use the automatic
      # nested error reporting that isn't as user-friendly
      sample_mixtures.each do |mixture|
        unless mixture.valid?
          error_message = mixture.errors.full_messages.join(",")
          errors.add(:sample, error_message) unless errors.on(:sample) && errors.on(:sample).include?(error_message)
        end
        mixture.samples.each do |sample|
          unless sample.valid?
            error_message = sample.errors.full_messages.join(",")
            errors.add(:sample, error_message) unless errors.on(:sample) && errors.on(:sample).include?(error_message)
          end
        end
      end
    end

    return false unless errors.empty?

    super
  end

  def save(perform_validation = true)
    return false if perform_validation && !valid?

    super

    # send notification email
    Notifier.deliver_sample_submission_notification(sample_mixtures, project && project.lab_group)

    return true
  end

  def project
    return Project.find_by_id(project_id)
  end

  def naming_scheme
    NamingScheme.find_by_id(naming_scheme_id)
  end

  private

  def self.normalize_mixture_attributes(attributes, deprecated_sample_attributes = nil)
    return nil unless attributes || deprecated_sample_attributes

    if attributes
      # if mixtures are given as key/value pairs, normalization is needed
      if attributes.respond_to?(:keys)
        attributes = hash_values_sorted_by_keys(attributes)
      end

      attributes.each_index do |i|
        samples = attributes[i].delete("samples_attributes") || attributes[i].delete("samples")
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
    else
      attributes = Array.new

      deprecated_sample_attributes.each do |sample_attributes|
        sample_mixture_attributes = {
          "name_on_tube" => sample_attributes.delete("name_on_tube"),
          "samples" => [{
            "sample_description" => sample_attributes.delete("sample_description") || sample_attributes.delete("sample_key")
          }]
        }

        sample_attributes.each do |key, value|
          sample_mixture_attributes["samples"][0][key] = value
        end

        attributes << sample_mixture_attributes
      end

      return attributes
    end
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
      *keys.collect{|key| [key, send(key)]}.flatten
    ]
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
