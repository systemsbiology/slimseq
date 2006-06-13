module HybridizationsHelper
  def error_messages_for_hybridizations(options = {})
    options = options.symbolize_keys
    error_message = "";
    for hybridization in @hybridizations
      unless hybridization.errors.empty?
        error_message << content_tag("div",
            content_tag(
            options[:header_tag] || "h2",
            "#{pluralize(hybridization.errors.count, "error")} prohibited hybridization from being saved"
            ) +
            content_tag("p", "There were problems with the following fields:") +
            content_tag("ul", hybridization.errors.full_messages.collect { |msg| content_tag("li", msg) }),
            "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
          )
      end
    end
    return error_message
  end
end
