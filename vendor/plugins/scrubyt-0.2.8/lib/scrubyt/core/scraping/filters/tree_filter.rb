module Scrubyt
  class TreeFilter < BaseFilter

    def evaluate(source)
      result = source/@xpath
      #puts "Evaluating #{@parent_pattern.name} with #{@xpath}"
      xpath_results = if result.class == Hpricot::Elements then result.map else [result] end
      if @regexp == nil
        xpath_results
      else
        regexp_results = []
        xpath_results.each do |entry|
          text = SharedUtils.prepare_text_for_comparison(result.inner_html)
          if text =~ @regexp
            regexp_results << $1
          end
        end
        regexp_results
      end
    end

    def generate_regexp_for_example
      return if @example_type != EXAMPLE_TYPE_STRING
      return if @temp_sink.nil?

      text = SharedUtils.prepare_text_for_comparison(@temp_sink.inner_text)
      match_range = @temp_sink.match_data.begin(0)..@temp_sink.match_data.end(0)
      return if match_range == (0..text.length)

      @regexp = text
      @temp_sink.changing_ranges.sort.reverse.each do |range|
        @regexp[range] = if range == match_range then '<<<regexp_selection>>>' else '<<<regexp_changing>>>' end
      end
      @regexp = Regexp.escape(@regexp)
      @regexp = @regexp.gsub('<<<regexp_changing>>>', '.*?')
      @regexp = @regexp.gsub('<<<regexp_selection>>>', '(.*?)')
      @regexp = '^' + @regexp + '$'
      @regexp = /#{@regexp}/
    end


    #For all the tree patterns, generate an XPath based on the given example
    #Also this method should not be called directly; It is automatically called for every tree
    #pattern directly after wrapper definition
    def generate_XPath_for_example(next_page_example=false)
      #puts "generating example for: #{@parent_pattern.name}"
      #puts @example_type
      case @example_type
      when EXAMPLE_TYPE_XPATH
        @xpath = @example
      when EXAMPLE_TYPE_STRING
        @temp_sink = SimpleExampleLookup.find_node_from_text(@parent_pattern.evaluation_context.root_pattern.filters[0].source[0],
                                                             @example,
                                                             next_page_example)
        return if @temp_sink == nil

        mark_changing_ranges = lambda { |element, range|
          element.instance_eval do
            @changing_ranges ||= [] << range
            def changing_ranges
              @changing_ranges
            end
          end
        }
        mark_changing_ranges.call(@temp_sink, @temp_sink.match_data.begin(0)..@temp_sink.match_data.end(0))

        @xpath = XPathUtils.generate_XPath(@temp_sink, nil, !@parent_pattern.generalize)
      when EXAMPLE_TYPE_CHILDREN
        current_example_index = 0
        loop do
          all_child_temp_sinks = []
          @parent_pattern.children.each do |child_pattern|
            all_child_temp_sinks << child_pattern.filters[current_example_index].temp_sink
          end
          result = all_child_temp_sinks.pop
          if all_child_temp_sinks.empty?
            result = result.parent
          else
            all_child_temp_sinks.each do |child_sink|
              result = XPathUtils.lowest_common_ancestor(result, child_sink)
            end
          end
          xpath = @parent_pattern.generalize ? XPathUtils.generate_XPath(result, nil, false) :
          XPathUtils.generate_XPath(result, nil, true)
          if @parent_pattern.filters.size < current_example_index + 1
            @parent_pattern.filters << Scrubyt::BaseFilter.create(@parent_pattern)
          end
          @parent_pattern.filters[current_example_index].xpath = xpath
          @parent_pattern.filters[current_example_index].temp_sink = result
          @parent_pattern.children.each do |child_pattern|
          next if child_pattern.type == :detail_page
            child_pattern.filters[current_example_index].xpath =
            child_pattern.generalize ? XPathUtils.generate_generalized_relative_XPath(child_pattern.filters[current_example_index].temp_sink, result) :
            XPathUtils.generate_relative_XPath(child_pattern.filters[current_example_index].temp_sink, result)
          end
          break if @parent_pattern.children[0].filters.size == current_example_index + 1
          current_example_index += 1
        end
      when EXAMPLE_TYPE_IMAGE
        #@temp_sink = XPathUtils.find_image(@parent_pattern.evaluation_context.root_pattern.filters[0].source[0], @example)\
        @temp_sink = XPathUtils.find_image(@parent_pattern.evaluation_context.extractor.get_hpricot_doc, @example)
        @xpath = XPathUtils.generate_XPath(@temp_sink, nil, false)
      when EXAMPLE_TYPE_COMPOUND
        @temp_sink = CompoundExampleLookup.find_node_from_compund_example(@parent_pattern.evaluation_context.root_pattern.filters[0].source[0],
                                                                          @example,
                                                                          next_page_example)
        @xpath = @parent_pattern.generalize ? XPathUtils.generate_XPath(@temp_sink, nil, false) :
        XPathUtils.generate_XPath(@temp_sink, nil, true)
      end
    end

    def generate_relative_XPath(parent_xpath)
      @xpath = XPathUtils.generate_relative_XPath_from_XPaths(parent_xpath, @xpath) if (@xpath =~ /^\/html/) #TODO: should not rely on <html> being the root node
    end

    def to_sexp
      [:str, @xpath]
    end

  end #End of class TreeFilter
end #End of module Scrubyt
