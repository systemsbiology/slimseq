module Scrubyt
  class DetailPageFilter < BaseFilter

    def evaluate(source)
      if source.is_a? String
        result = @parent_pattern.evaluation_context.extractor.evaluate_subextractor(source, @parent_pattern, @parent_pattern.resolve)
      else
        result = @parent_pattern.evaluation_context.extractor.evaluate_subextractor(
          XPathUtils.find_nearest_node_with_attribute(source, 'href').attributes['href'],
          @parent_pattern, @parent_pattern.resolve)
      end
    end #end of method
  end #End of class DetailPageFilter
end #End of module Scrubyt
