#class SampleSet < ActiveRecord::BaseWithoutTable
class SampleSet < ActiveRecord::Base
  has_many :sample_mixtures

  after_save :send_notification

  validate :at_least_one_sample_mixture

  def self.parse_api(attributes)
    sample_set = SampleSet.new

    required_keys = [
      "budget_number", "eland_parameter_set_id", "primer_id", "project_id", "platform_id",
      "insert_size", "reference_genome_id", "naming_scheme_id", "read_format", "sample_mixtures"
    ]
    required_keys.each do |key|
      unless attributes.has_key? key
        sample_set.errors.add_to_base "#{key.humanize} must be provided"
      end
    end

    unless attributes["submitted_by_id"]
      attributes["submitted_by_id"] = User.find_by_login(attributes["submitted_by"]).id
    end

    shared_mixture_attributes = {
      :budget_number => attributes["budget_number"],
      :submission_date => parse_multi_field_date(attributes) || Date.today,
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
    elsif attributes["custom_prep_kit_name"] && attributes["custom_prep_kit_name"].size > 0
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
    elsif attributes["custom_primer_name"] && attributes["custom_primer_name"].size > 0
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

    # normalize sample_mixtures
    if attributes["sample_mixtures"].is_a? Hash
      attributes["sample_mixtures"] = hash_values_sorted_by_keys(attributes["sample_mixtures"])
    end

    return SampleSet.new unless attributes["sample_mixtures"]

    attributes["sample_mixtures"].each do |mixture_attributes|
      mixture_attributes = mixture_attributes.merge(shared_mixture_attributes)
      samples_attributes = mixture_attributes.delete("samples")
      postback_uri = mixture_attributes.delete("postback_uri")
      sample_mixture = sample_set.sample_mixtures.build(mixture_attributes)

      if samples_attributes.is_a? Hash
        samples_attributes = hash_values_sorted_by_keys(samples_attributes)
      end

      if samples_attributes
        samples_attributes.each do |sample_attributes|
          sample_attributes = sample_attributes.merge(shared_sample_attributes)

          sample_mixture.samples.build(sample_attributes)
        end
      else
        sample_attributes = shared_sample_attributes

        # use the postback uri provided at the mixture level if one isn't provided at the sample level
        unless sample_attributes["sample_description"]
          sample_attributes = sample_attributes.merge("sample_description" => mixture_attributes["sample_description"])
        end

        unless sample_attributes["postback_uri"]
          sample_attributes = sample_attributes.merge("postback_uri" => postback_uri)
        end

        sample_mixture.samples.build(sample_attributes)
      end

      reads_attributes.each do |read_attributes|
        sample_mixture.desired_reads.build(read_attributes)
      end
    end
    
    return sample_set
  end

  def error_message
    messages = errors.full_messages
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

  private

  def send_notification
    # send notification email
    project = Project.find_by_id(sample_mixtures.first.project_id)
    Notifier.deliver_sample_submission_notification(sample_mixtures, project && project.lab_group)

    return true
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

  def self.hash_values_sorted_by_keys(hash)
    hash.sort.collect{|element| element[1]}
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

  def at_least_one_sample_mixture
    errors.add(:sample_mixtures, "must be provided") unless sample_mixtures.size >= 1
  end
end
