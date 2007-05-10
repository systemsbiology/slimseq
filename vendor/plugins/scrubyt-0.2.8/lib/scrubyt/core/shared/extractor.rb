module Scrubyt
  ##
  #=<tt>Driving the whole extraction process</tt>
  #
  #Extractor is a performer class - it gets an extractor definition and carries
  #out the actions and evaluates the wrappers sequentially.
  #
  #Originally also the navigation actions were here, but since the class got too
  #big, they were factored out to an own class, NavigationAction.
  class Extractor
    #The definition of the extractor is passed through this method
    def self.define(mode=nil, &extractor_definition)
      backtrace = SharedUtils.get_backtrace
      parts = backtrace[1].split(':')
      source_file = parts[0]

      @@mode = mode
      #We are keeping the relations between the detail patterns and their root patterns
      @@detail_extractor_to_pattern_name = {}
      @@detail_pattern_relations = {}
      #root pattern -> URIBuilder mapping
      @@next_patterns = {}
      mode_name = (mode == :production ? 'Production' : 'Learning')
      puts "[MODE] #{mode_name}"
      NavigationActions.new
      @@evaluation_context = EvaluationContext.new
      #Hack up an artificial root pattern (i.e. do not return the pattern which
      #is the root one in the user's definition, but rather the real (invisible)
      #root pattern
      @@evaluation_context.evaluating_extractor_definition = true
      class_eval(&extractor_definition)
      @@evaluation_context.evaluating_extractor_definition = false
      root_pattern = @@evaluation_context.root_pattern
      if root_pattern.nil?
        puts "No extractor defined, exiting..."
        exit
      end
      root_pattern.source_file = source_file
      root_pattern.source_proc = extractor_definition
      #Once all is set up, evaluate the extractor from the root pattern!
      evaluate_extractor(root_pattern)
      #Apply all postprocess steps
      PostProcessor.apply_post_processing(root_pattern)
      #Return the root pattern
      puts "Extraction finished succesfully!"
      root_pattern
    end

    #Evaluate a subexttractor (i.e. an extractor on a detail page).
    #The url passed to this function is automatically loaded.
    #The definition of the subextractor is passed as a block
    #
    #!!!! THIS CODE IS A MESS, IT needs to be refactored ASAP....
    def self.evaluate_subextractor(url, parent_pattern, resolve)
      if @@detail_pattern_relations.keys.include? @@detail_extractor_to_pattern_name[parent_pattern.referenced_extractor]
        detail_root = @@detail_pattern_relations[@@detail_extractor_to_pattern_name[parent_pattern.referenced_extractor]].parent
        detail_root.result = Result.new
        detail_root.last_result = nil
        FetchAction.store_page
        @@original_evaluation_context.push @@evaluation_context
        @@host_stack.push FetchAction.get_host_name
        @@evaluation_context = EvaluationContext.new
        @@evaluation_context.clear_sources_and_sinks detail_root
        FetchAction.restore_host_name
        fetch url, :resolve => resolve
        @@evaluation_context.extractor = self
        @@evaluation_context.root_pattern = detail_root
        @@evaluation_context.attach_current_document
        evaluate_extractor detail_root
        @@evaluation_context = @@original_evaluation_context.pop
        FetchAction.restore_page
        FetchAction.store_host_name(@@host_stack.pop)
        detail_root.to_xml
      else
        @@original_evaluation_context ||= []
        @@host_stack ||= []
        FetchAction.store_page
        @@original_evaluation_context.push @@evaluation_context
        @@host_stack.push FetchAction.get_host_name
        @@evaluation_context = EvaluationContext.new
        FetchAction.restore_host_name
        fetch url, :resolve => resolve
        evaluated_extractor = (class_eval(&parent_pattern.referenced_extractor))
        root_pattern = evaluated_extractor.parent
        @@detail_pattern_relations[@@detail_extractor_to_pattern_name[parent_pattern.referenced_extractor]] = root_pattern.children[0]
        evaluate_extractor(root_pattern)
        #Apply all postprocess steps
        PostProcessor.apply_post_processing(root_pattern)
        @@evaluation_context = @@original_evaluation_context.pop
        FetchAction.restore_page
        FetchAction.store_host_name(@@host_stack.pop)
        root_pattern.to_xml
      end
    end

    #build the current wrapper
    def self.method_missing(method_name, *args, &block)
      if NavigationActions::KEYWORDS.include? method_name.to_s
        NavigationActions.send(method_name, *args)
        return
      end
      if method_name.to_s == 'next_page'
        pattern = Scrubyt::Pattern.new(method_name.to_s, args, @@evaluation_context)
        pattern.evaluation_context = @@evaluation_context

        @@evaluation_context.setup_uri_builder(pattern, args)
        @@next_patterns[@@last_root_pattern] = @@evaluation_context.uri_builder
      else
        raise "Only one root pattern allowed" if !@@evaluation_context.root_pattern.nil?
        #Create a root pattern
        root_pattern = Scrubyt::Pattern.new('root', [:type => :root], @@evaluation_context)
        @@last_root_pattern = root_pattern
        @@evaluation_context.root_pattern = root_pattern
        @@evaluation_context.extractor = self
        #add the currently active document to the root pattern
        @@evaluation_context.attach_current_document
        pattern = Scrubyt::Pattern.new(method_name.to_s, args, @@evaluation_context, root_pattern, &block)
        root_pattern.children << pattern
        pattern
      end
    end

    def self.add_detail_extractor_to_pattern_name(referenced_extractor, pattern)
      @@detail_extractor_to_pattern_name[referenced_extractor] ||= [] << pattern
    end

    def self.get_detail_extractor(parent_pattern)
      @@detail_pattern_relations[@@detail_extractor_to_pattern_name[parent_pattern.referenced_extractor]].parent
    end

    def self.get_hpricot_doc
      NavigationActions.get_hpricot_doc
    end

    def self.get_current_doc_url
      NavigationActions.get_current_doc_url
    end

    def self.get_detail_pattern_relations
      @@detail_pattern_relations
    end

    def self.get_host_name
      NavigationActions.get_host_name
    end

    def self.get_mode
      @@mode
    end

    def self.get_original_host_name
      @@original_host_name
    end

    private

    def self.evaluate_extractor(root_pattern)
      if @@next_patterns[root_pattern]
        current_page_count = 1
        loop do
          root_pattern.evaluate(nil)
          break if (@@next_patterns[root_pattern].limit == current_page_count || !@@evaluation_context.crawl_to_new_page(root_pattern, @@next_patterns[root_pattern]))
          current_page_count += 1 if @@next_patterns[root_pattern].limit != nil
        end
      else
        root_pattern.evaluate(nil)
      end
    end

  end #end of class Extractor
end #end of module Scrubyt
