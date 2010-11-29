#class SampleSet < ActiveRecord::BaseWithoutTable
class SampleSet < ActiveRecord::Base
  has_many :sample_mixtures

  def self.parse_api(attributes)
    unless attributes["submitted_by_id"]
      attributes["submitted_by_id"] = User.find_by_login(attributes["submitted_by"]).id
    end

    shared_mixture_attributes = {
      :budget_number => attributes["budget_number"],
      :submission_date => parse_multi_field_date(attributes),
      :eland_parameter_set_id => attributes["eland_parameter_set_id"],
      :primer_id => attributes["primer_id"],
      :project_id => attributes["project_id"],
      :platform_id => attributes["platform_id"],
      :submitted_by_id => attributes["submitted_by_id"]
    }
    shared_sample_attributes = {
      :insert_size => attributes["insert_size"],
      :reference_genome_id => attributes["reference_genome_id"],
      :naming_scheme_id => attributes["naming_scheme_id"]
    }

    if attributes["sample_prep_kit_id"].to_i > 0
      shared_mixture_attributes = shared_mixture_attributes.merge(
        :sample_prep_kit_id => attributes["sample_prep_kit_id"]
      )
    elsif attributes["custom_prep_kit_id"].to_i > 0
      shared_mixture_attributes = shared_mixture_attributes.merge(
        :sample_prep_kit_id => attributes["custom_prep_kit_id"]
      )
    elsif attributes["custom_prep_kit_name"].size > 0
      shared_mixture_attributes = shared_mixture_attributes.merge(
        :sample_prep_kit_id => SamplePrepKit.create(
          :name => attributes["custom_prep_kit_name"],
          :platform_id => attributes["platform_id"].id,
          :custom => true )
      )
    end

    if attributes["primer_id"].to_i > 0
      shared_mixture_attributes = shared_mixture_attributes.merge(
        :primer_id => attributes["primer_id"]
      )
    elsif attributes["custom_primer_id"].to_i > 0
      shared_mixture_attributes = shared_mixture_attributes.merge(
        :primer_id => attributes["custom_primer_id"]
      )
    elsif attributes["custom_primer_name"].size > 0
      shared_mixture_attributes = shared_mixture_attributes.merge(
        :primer_id => Primer.create(
          :name => attributes["custom_primer_name"],
          :platform_id => attributes["platform_id"].id,
          :custom => true )
      )
    end

    case attributes["read_format"]
    when "Single read"
      reads_attributes = [
        { :desired_read_length => attributes["desired_read_length"],
          :alignment_start_position => attributes["alignment_start_position"],
          :alignment_end_position => attributes["alignment_end_position"] }
      ]
    when "Paired end read"
      reads_attributes = [
        { :desired_read_length => attributes["desired_read_length_1"],
          :alignment_start_position => attributes["alignment_start_position_1"],
          :alignment_end_position => attributes["alignment_end_position_1"] },
        { :desired_read_length => attributes["desired_read_length_2"],
          :alignment_start_position => attributes["alignment_start_position_2"],
          :alignment_end_position => attributes["alignment_end_position_2"] }
      ]
    end

    sample_set = SampleSet.new
    attributes["sample_mixtures"].sort.each do |index, mixture_attributes|
      mixture_attributes = mixture_attributes.merge(shared_mixture_attributes)
      samples_attributes = mixture_attributes.delete("samples")
      sample_mixture = sample_set.sample_mixtures.build(mixture_attributes)

      samples_attributes.sort.each do |index, sample_attributes|
        sample_attributes = sample_attributes.merge(shared_sample_attributes)
        sample_mixture.samples.build(sample_attributes)
      end

      reads_attributes.each do |read_attributes|
        sample_mixture.desired_reads.build(read_attributes)
      end
    end
    
    return sample_set
  end

  def error_message
    messages = Array.new
    message = ""

    sample_mixtures.each do |mixture|
      unless mixture.valid?
        mixture.samples.each do |sample|
          if sample.valid?
            mixture.errors.each do |error|
              messages << "#{error[0].humanize} #{error[1]}"
            end
          else
            sample.errors.each do |error|
              messages << "#{error[0].humanize} #{error[1]}"
            end 
          end
        end
      end
    end

    message += messages.uniq.join(", ")

    return message
  end

  #def self.new(attributes=nil)
  #  mixture_attributes = attributes.delete("sample_mixtures_attributes") || attributes.delete("sample_mixtures") if attributes
  #  deprecated_sample_attributes = attributes.delete("samples") if attributes

  #  parse_multi_field_date(attributes)
  #  sample_set = super

  #  sample_set.alignment_start_position ||= 1
  #  sample_set.submission_date ||= Date.today

  #  # build empty sample mixtures and samples
  #  # these will be replaced if sample mixture attributes have been provided
  #  sample_set.build_blank_mixtures_and_samples
  #  sample_set.submission_step = 1

  #  normalized_mixture_attributes = normalize_mixture_attributes(mixture_attributes, deprecated_sample_attributes)
  #  sample_set.load_mixture_attributes(normalized_mixture_attributes)

  #  return sample_set
  #end

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

  #def valid?
  #  if submission_step == 2
  #    # manually collect errors across sample_mixtures and samples, rather than use the automatic
  #    # nested error reporting that isn't as user-friendly
  #    sample_mixtures.each do |mixture|
  #      unless mixture.valid?
  #        error_message = mixture.errors.full_messages.join(",")
  #        errors.add(:sample, error_message) unless errors.on(:sample) && errors.on(:sample).include?(error_message)
  #      end
  #      mixture.samples.each do |sample|
  #        unless sample.valid?
  #          error_message = sample.errors.full_messages.join(",")
  #          errors.add(:sample, error_message) unless errors.on(:sample) && errors.on(:sample).include?(error_message)
  #        end
  #      end
  #    end
  #  end

  #  return false unless errors.empty?

  #  super
  #end

  def save(perform_validation = true)
    return false if perform_validation && !valid?

    super

    # send notification email
    project = Project.find_by_id(sample_mixtures.first.project_id)
    Notifier.deliver_sample_submission_notification(sample_mixtures, project && project.lab_group)

    return true
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
      "eland_parameter_set_id", "submitted_by", "platform_id"
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
    if attributes["date(1i)"]
      return Date.new(
        attributes.delete("date(1i)").to_i,
        attributes.delete("date(2i)").to_i,
        attributes.delete("date(3i)").to_i
      )
    end
  end
end
