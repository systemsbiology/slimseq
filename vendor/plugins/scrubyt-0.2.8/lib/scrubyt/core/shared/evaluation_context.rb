module Scrubyt
  ##
  #=<tt>Holding the evaluation context of the extraction process</tt>
  #
  #Every kind of data that is shared among patterns during the extraction process
  #is held in this class, so it can be looked up anytime.
  #
  #This class provides also some high-level basic functionality in navigation, like 
  #crawling to new pages, attaching doucment to the root pattern once arrived at the
  #desired page etc.
  #
  #It can be viewed as a glue between Extractor and NavigationActions as well - these
  #two classes need to communicate frequently as well as share different information
  #and this is accomplished through EvaluationContext.
  class EvaluationContext
    attr_accessor :root_pattern, :document_index, :extractor, :uri_builder, :evaluating_extractor_definition
    
    def initialize
      @root_pattern = nil
      @next_page = nil
      @document_index = 0
      @extractor = nil
      @evaluating_extractor_definition = false
    end
    
    ##
    #Crawl to a new page. This function should not be called from the outside - it is automatically called
    #if the next_page pattern is defined
    def crawl_to_new_page(root_pattern, uri_builder)
      temp_document = uri_builder.next_page_example ? 
                        generate_next_page_link(uri_builder) : 
                        uri_builder.generate_next_uri
      return nil if temp_document == nil
      clear_sources_and_sinks(@root_pattern)
      FetchAction.restore_host_name
      @extractor.fetch(temp_document)
      attach_current_document
    end

    ##
    #Attach document to the root pattern; This is happening automatically as the root pattern is defined or
    #crawling to a new page
    def attach_current_document
      doc = @extractor.get_hpricot_doc
      @root_pattern.filters[0].source << doc
      @root_pattern.filters[0].sink << doc      
      @root_pattern.last_result ||= []
      @root_pattern.last_result << doc  
      @root_pattern.result.add_result(@root_pattern.filters[0].source, 
                                      @root_pattern.filters[0].sink)
    end
    
    ##
    #After crawling to the new page, the sources and sinks need to be cleaned
    #since they are no more valid 
    def clear_sources_and_sinks(pattern)
      pattern.filters.each do |filter|
        filter.source = []
        filter.sink = []
      end
      pattern.children.each {|child| clear_sources_and_sinks child}
    end
    
    def generate_next_page_link(uri_builder)
      uri_builder.next_page_pattern.filters[0].generate_XPath_for_example(true)
      xpath = uri_builder.next_page_pattern.filters[0].xpath
      node = (@extractor.get_hpricot_doc/xpath).map.last
      node = XPathUtils.find_nearest_node_with_attribute(node, 'href')
      return nil if node == nil || node.attributes['href'] == nil      
      node.attributes['href'].gsub('&amp;') {'&'}
    end         
            
    def setup_uri_builder(pattern,args)
      if args[0] =~ /^http.+/
        args.insert(0, @extractor.get_current_doc_url) if args[1] !~ /^http.+/
      end
      @uri_builder = URIBuilder.new(pattern,args)
    end
  end #end of class EvaluationContext
end #end of module Scrubyt
