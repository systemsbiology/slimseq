module SamplesHelper
  def error_messages_for_samples(options = {})
    options = options.symbolize_keys
    error_message = "";
    for sample in @samples
      unless sample.errors.empty?
        error_message << content_tag("div",
            content_tag(
            options[:header_tag] || "h2",
            "#{pluralize(sample.errors.count, "error")} prohibited sample from being saved"
            ) +
            content_tag("p", "There were problems with the following fields:") +
            content_tag("ul", sample.errors.full_messages.collect { |msg| content_tag("li", msg) }),
            "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
          )
      end
    end
    return error_message
  end
end
