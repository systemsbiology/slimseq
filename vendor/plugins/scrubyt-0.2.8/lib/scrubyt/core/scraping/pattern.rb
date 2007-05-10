require 'rubygems'
require 'hpricot'

module Scrubyt
  ##
  #=<tt>Group more filters into one</tt>
  #
  #Server as an umbrella for filters which are conceptually extracting
  #the same thing - for example a price or a title or ...
  #
  #Sometimes the same piece of information can not be extracted with one filter
  #across more result instances (for example a price has an XPath in record n,
  #but since in record n+1 has a discount price as well, the real price is pushed
  #to a different XPath etc) - in this case the more filters which extract the same
  #thing are hold in the same pattern.
  class Pattern
    #Type of the pattern;

    # TODO: Update documentation

    #    # a root pattern represents a (surprise!) root pattern
    #    PATTERN_TYPE_ROOT = :PATTERN_TYPE_ROOT
    #    # a tree pattern represents a HTML region
    #    PATTERN_TYPE_TREE = :PATTERN_TYPE_TREE
    #    # represents an attribute of the node extracted by the parent pattern
    #    PATTERN_TYPE_ATTRIBUTE = :PATTERN_TYPE_ATTRIBUTE
    #    # represents a pattern which filters its output with a regexp
    #    PATTERN_TYPE_REGEXP = :PATTERN_TYPE_REGEXP
    #    # represents a pattern which crawls to the detail page and extracts information from there
    #    PATTERN_TYPE_DETAIL_PAGE = :PATTERN_TYPE_DETAIL_PAGE
    #    # represents a download pattern
    #    PATTERN_TYPE_DOWNLOAD = :PATTERN_TYPE_DOWNLOAD
    #    # write out the HTML subtree beginning at the matched element
    #    PATTERN_TYPE_HTML_SUBTREE = :PATTERN_TYPE_HTML_SUBTREE

    VALID_PATTERN_TYPES = [:root, :tree, :attribute, :regexp, :detail_page, :download, :html_subtree]

    #The pattern can be either a model pattern (in this case it is
    #written to the output) or a temp pattern (in this case it is skipped)
    #Will be implemented in a higher version (i.e. not 0.1.0) - for now, everything
    #is considered to be a model pattern

    #Model pattern are shown in the output
    #    OUTPUT_TYPE_MODEL = :OUTPUT_TYPE_MODEL
    #    #Temp patterns are skipped in the output (their ancestors are appended to the parent
    #    #of the pattrern which was skipped
    #    OUTPUT_TYPE_TEMP = :OUTPUT_TYPE_TEMP

    VALID_OUTPUT_TYPES = [:model, :temp]

    #These options can be set upon wrapper creation
    VALID_OPTIONS = [:generalize, :type, :output_type, :write_text, :references, :limit, :default, :resolve]  + Scrubyt::CompoundExample::DESCRIPTORS

    attr_accessor(:name, :options, :children, :constraints, :filters, :parent,
                  :last_result, :result, :evaluation_context,
                  :indices_to_extract, :referenced_extractor, :referenced_pattern,
                  :source_file, :source_proc, :modifier_calls)

    attr_reader(:next_page_url, :result_indexer)

    option_reader(:type => :tree, :output_type => :model, :generalize => false,
                  :write_text => lambda { @children.size == 0 }, :limit => nil,
                  :default => nil, :resolve => :full)

    def initialize(name, args=[], evaluation_context=nil, parent=nil, &block)
      #init attributes
      @name = name
      @evaluation_context = evaluation_context
      @parent = parent
      @options = {}
      @children = []
      @filters = []
      @constraints = []
      @result = Result.new
      @modifier_calls = []

      #grab any examples that are defined
      examples = look_for_examples(args)

      #parse the options hash if provided
      parse_options_hash(args[-1]) if args[-1].is_a? Hash

      #perform checks for special cases
      examples = check_if_shortcut_pattern() if examples == nil
      check_if_detail_page(block)

      #create filters
      if examples == nil
        @filters << Scrubyt::BaseFilter.create(self) #create a default filter
      else
        examples.each do |example|
          @filters << Scrubyt::BaseFilter.create(self,example) #create a filter
        end
      end

      #by default, generalize direct children of the root pattern, but only in the case if
      #@generalize was not set up explicitly
      @options[:generalize] = true if parent && parent.type == :root && @options[:generalize].nil?

      #parse child patterns if available
      parse_child_patterns(&block) if ( !block.nil? && type != :detail_page )

      #tree pattern only (TODO: subclass?)
      if type == :tree
        #generate xpaths and regexps
        @filters.each do |filter|
          filter.generate_XPath_for_example(false)
          filter.generate_regexp_for_example
        end
        #when the xpaths of this pattern have been created, its children can make their xpaths relative
        xpaths = @filters.collect { |filter| filter.xpath }
        @children.each do |child|
          child.generate_relative_XPaths xpaths
        end
      end
    end

    def generate_relative_XPaths(parent_xpaths)
      return if type != :tree
      raise ArgumentError.new if parent_xpaths.size != 1 && parent_xpaths.size != @filters.size #TODO: should be checked earlier with proper error message
      @filters.each_index do |index|
        @filters[index].generate_relative_XPath parent_xpaths[parent_xpaths.size == 1 ? 0 : index]
      end
    end

    #Shortcut patterns, as their name says, are a shortcut for creating patterns
    #from predefined rules; for example:
    #
    #  detail_url
    #
    #  is equivalent to
    #
    #  detail_url 'href', type => :attribute
    #
    #i.e. the system figures out on it's own that because of the postfix, the
    #example should be looked up (but it should never override the user input!)
    #another example (will be available later):
    #
    # every_img
    #
    # is equivivalent to
    #
    # every_img '//img'
    #
    def check_if_shortcut_pattern()
      if @name =~ /.+_url/
        @options[:type] = :attribute
        ['href']
      end
    end

    #Check whether the currently created pattern is a detail pattern (i.e. it refrences
    #a subextractor). Also check if the currently created pattern is
    #an ancestor of a detail pattern , and store this in a hash if yes (to be able to
    #traverse the pattern structure on detail pages as well).
    def check_if_detail_page(block)
      #return if !@options[:references]
      #@options[:type] = :detail_page
      #@referenced_extractor = @options[:references]
      if @name =~ /.+_detail/
        @options[:type] = :detail_page
        @referenced_extractor = block
        Scrubyt::Extractor.add_detail_extractor_to_pattern_name(block, self)
      end
    end

    def parent_of_leaf
      @children.inject(false) { |is_parent_of_leaf, child| is_parent_of_leaf || child.children.empty? }
    end

    def parse_child_patterns(&block)
      context = Object.new
      context.instance_eval do
        def current=(value)
          @current = value
        end
        def method_missing(method_name, *args, &block)
          if method_name.to_s[0..0] == '_'
            #add hash option
            key = :"#{method_name.to_s[1..-1]}"
            args.each do |arg|
              current_value = @current.options[key]
              if current_value.nil?
                @current.options[key] = arg
              else
                @current.options[key] = [current_value] if !current_value.is_a Array
                @current.options[key] << arg
              end
            end
          else
            #create child pattern
            child = Scrubyt::Pattern.new(method_name.to_s, args, @current.evaluation_context, @current, &block)
            @current.children << child
            child
          end
        end
      end
      context.current = self
      context.instance_eval(&block)
    end

    #Dispatcher function; The class was already too big so I have decided to factor
    #out some methods based on their functionality (like output, adding constraints)
    #to utility classes.
    #
    #The second function besides dispatching is to lookup the results in an evaluated
    #wrapper, for example
    #
    # camera_data.item[1].item_name[0]
    def method_missing(method_name, *args, &block)
      if @evaluation_context.evaluating_extractor_definition
        @modifier_calls << [method_name, [:array, *args.collect { |arg| [:lit, arg] }]]
      end

      case method_name.to_s
      when 'select_indices'
        @result_indexer = Scrubyt::ResultIndexer.new(*args)
        return self
      when /^to_/
        return Scrubyt::ResultDumper.send(method_name.to_s, self)
      when /^ensure_/
        @constraints << Scrubyt::ConstraintAdder.send(method_name, *args)
        return self #To make chaining possible
      else
        @children.each { |child| return child if child.name == method_name.to_s }
      end

      raise NoMethodError.new(method_name.to_s, method_name.to_s, args)
    end

    #Companion function to the previous one (Pattern::method_missing). It makes
    #inspecting results, like
    #
    #    camera_data.item[1].item_name[0]
    #
    #possible. The method Pattern::method missing handles the 'item', 'item_name' etc.
    #parts, while the indexing ([1], [0]) is handled by this function.
    #If you would like to select a different document than the first one (which is
    #the default), you should use the form:
    #
    #    camera_data[1].item[1].item_name[0]
    def [](index)
      if @name == 'root'
        @evaluation_context.document_index = index
      else
        @parent.last_result = @parent.last_result[@evaluation_context.document_index] if @parent.last_result.is_a? Array
        return nil if (@result.lookup(@parent.last_result)) == nil
        @last_result = @result.lookup(@parent.last_result)[index]
      end
      self
    end

    ##
    #If export is called on the root pattern, it exports the whole extractor wher it is
    #defined; See export.rb for further details on the parameters
    def export(arg1, output_file_name=nil, extractor_result_file_name=nil)
      #      require 'scrubyt/output/export_old'; Scrubyt::ExportOld.export(arg1, self, output_file_name, extractor_result_file_name) ; return
      if File.exists? arg1
        old_export(arg1, output_file_name, extractor_result_file_name)
      else
        new_export(arg1, output_file_name, extractor_result_file_name)
      end
    end

    def old_export(input_file, output_file_name=nil, extractor_result_file_name=nil)
      contents = open(input_file).read
      wrapper_name = contents.scan(/\s+(.+)\s+=.*Extractor\.define.*/)[0][0]
      Scrubyt::Export.export(self, wrapper_name, output_file_name, extractor_result_file_name)
    end

    def new_export(wrapper_name, output_file_name=nil, extractor_result_file_name=nil)
      Scrubyt::Export.export(self, wrapper_name, output_file_name, extractor_result_file_name)
    end

    ##
    #Evaluate the pattern. This means evaluating all the filters and adding
    #their extracted instances to the array of results of this pattern
    def evaluate(parent_filters)
      if type != :root #TODO: should be removed, but there is more refactoring of filter handling needed to do so
        all_filter_results = []
        @filters.each do |filter|
          filter_index = @filters.index(filter)
          filter_index = 0 if parent_filters.size <= filter_index
          filter.source = parent_filters[filter_index].sink
          filter.source.each do |source|
            results = filter.evaluate(source)
            next if results == nil
            #apply constraints
            if @constraints.size > 0
              results = results.select do |result|
                @constraints.inject(true) { |accepted, constraint| accepted && constraint.check(result) }
              end
            end
            #apply indexer
            results = @result_indexer.select_indices_to_extract(results) if !@result_indexer.nil?
            add_result(filter, source, results)
          end
        end
      end

      #evaluate children
      @children.each { |child| child.evaluate(@filters) }

      #do postprocessing
    end

    def to_sexp
      #collect arguments
      args = []
      args.push(*@filters.to_sexp_array) if type != :detail_page #TODO: this if shouldn't be there
      args.push(@options.to_sexp) if !@options.empty?

      #build main call
      sexp = [:fcall, @name, [:array, *args]]

      if type == :detail_page
        #add detail page extractor
        detail_root = @evaluation_context.extractor.get_detail_extractor(self)
        sexp = [:iter, sexp, nil, [:block, *detail_root.children.to_sexp_array ]]
      else
        #add child block if the pattern has children
        sexp = [:iter, sexp, nil, [:block, *@children.to_sexp_array ]] if !@children.empty?
      end

      #add modifier calls - TODO: remove when everything is exported to the options hash
      @modifier_calls.each do |modifier_sexp|
        sexp = [:call, sexp, *modifier_sexp]
      end

      #return complete sexp
      sexp
    end

    private
    def parse_options_hash(hash)
      #merge provided hash
      @options.merge!(hash)
      #check if valid
      hash.each { |key, value| raise "Unknown pattern option: #{key.to_s}" if VALID_OPTIONS.index(key.to_sym).nil? }
      raise "Invalid pattern type: #{type.to_s}" if VALID_PATTERN_TYPES.index(type.to_sym).nil?
      raise "Invalid output type: #{output_type.to_s}" if VALID_OUTPUT_TYPES.index(output_type.to_sym).nil?
    end

    def look_for_examples(args)
      if (args[0].is_a? String)
        examples = args.select {|e| e.is_a? String}
        #Check if all the String parameters are really the first
        #parameters
        args[0..examples.size-1].each do |example|
          if !example.is_a? String
            puts 'FATAL: Problem with example specification'
          end
        end
      elsif (args[0].is_a? Regexp)
        examples = args.select {|e| e.is_a? Regexp}
        #Check if all the String parameters are really the first
        #parameters
        args[0..examples.size].each do |example|
          if !example.is_a? Regexp
            puts 'FATAL: Problem with example specification'
          end
        end
        @options[:type] = :regexp
      elsif (args[0].is_a? Hash)
        examples = (args.select {|e| e.is_a? Hash}).select {|e| CompoundExample.compound_example?(e)}
        examples = nil if examples == []
      end

      @has_examples = !examples.nil?
      examples
    end

    def add_result(filter, source, results)
      results.each do |res|
        filter.sink << res
        @result.add_result(source, res)
      end
    end

  end #end of class Pattern
end #end of module Scrubyt
