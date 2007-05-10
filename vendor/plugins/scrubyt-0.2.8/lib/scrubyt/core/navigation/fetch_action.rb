module Scrubyt
  ##
  #=<tt>Fetching pages (and related functionality)</tt>
  #
  #Since lot of things are happening during (and before)
  #the fetching of a document, I decided to move out fetching related
  #functionality to a separate class - so if you are looking for anything
  #which is loading a document (even by submitting a form or clicking a link)
  #and related things like setting a proxy etc. you should find it here.
  class FetchAction
    def initialize
      @@current_doc_url = nil
      @@current_doc_protocol = nil
      @@base_dir = nil
      @@host_name = nil
      @@agent = WWW::Mechanize.new
      @@history = []
    end

    ##
    #Action to fetch a document (either a file or a http address)
    #
    #*parameters*
    #
    #_doc_url_ - the url or file name to fetch
    def self.fetch(doc_url, *args)
      #Refactor this crap!!! with option_accessor stuff
      proxy = args[0][:proxy]
      mechanize_doc = args[0][:mechanize_doc]
      resolve = args[0][:resolve] || :full
      basic_auth = args[0][:basic_auth]
      user_agent = args[0][:user_agent] || "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"
      #Refactor this whole stuff as well!!! It looks awful...
      parse_and_set_proxy(proxy) if proxy
      set_user_agent(user_agent)
      parse_and_set_basic_auth(basic_auth) if basic_auth
      if !mechanize_doc
        @@current_doc_url = doc_url
        @@current_doc_protocol = determine_protocol
        handle_relative_path(doc_url)
        handle_relative_url(doc_url,resolve)
        puts "[ACTION] fetching document: #{@@current_doc_url}"
        if @@current_doc_protocol != 'file'
          @@mechanize_doc = @@agent.get(@@current_doc_url)
        end
      else
        @@current_doc_url = doc_url
        @@mechanize_doc = mechanize_doc
        @@current_doc_protocol = determine_protocol
      end
      if @@current_doc_protocol == 'file'
        @@hpricot_doc = Hpricot(PreFilterDocument.br_to_newline(open(@@current_doc_url).read))
      else
        @@hpricot_doc = Hpricot(PreFilterDocument.br_to_newline(@@mechanize_doc.body))
        store_host_name(self.get_current_doc_url)   # in case we're on a new host
      end
    end

    ##
    #Submit the last form;
    def self.submit(current_form, button=nil)
      puts '[ACTION] submitting form...'
      if button == nil
        result_page = @@agent.submit(current_form)
      else
        result_page = @@agent.submit(current_form, button)
      end
      @@current_doc_url = result_page.uri.to_s
      puts "[ACTION] fetched #{@@current_doc_url}"
      fetch(@@current_doc_url, :mechanize_doc => result_page)
    end

    ##
    #Click the link specified by the text
    def self.click_link(link_spec,index = 0)
      print "[ACTION] clicking link specified by: "; p link_spec
      if link_spec.is_a? Hash
        clicked_elem = CompoundExampleLookup.find_node_from_compund_example(@@hpricot_doc, link_spec, false, index)
      else
        clicked_elem = SimpleExampleLookup.find_node_from_text(@@hpricot_doc, link_spec, false, index)
      end
      clicked_elem = XPathUtils.find_nearest_node_with_attribute(clicked_elem, 'href')
      result_page = @@agent.click(clicked_elem)
      @@current_doc_url = result_page.uri.to_s
      puts "[ACTION] fetched #{@@current_doc_url}"
      fetch(@@current_doc_url, :mechanize_doc => result_page)
    end

    ##
    # At any given point, the current document can be queried with this method; Typically used
    # when the navigation is over and the result document is passed to the wrapper
    def self.get_current_doc_url
      @@current_doc_url
    end

    def self.get_mechanize_doc
      @@mechanize_doc
    end

    def self.get_hpricot_doc
      @@hpricot_doc
    end

    def self.get_host_name
      @@host_name
    end

    def self.restore_host_name
      return if @@current_doc_protocol == 'file'
      @@host_name = @@original_host_name
    end

    def self.store_page
      @@history.push @@hpricot_doc
    end

    def self.restore_page
      @@hpricot_doc = @@history.pop
    end

    def self.determine_protocol
      old_protocol = @@current_doc_protocol
      new_protocol = case @@current_doc_url
        when /^https/
          'https'
        when /^http/
          'http'
        when /^www/
          'http'
        else
          'file'
        end
      return 'http' if ((old_protocol == 'http') && new_protocol == 'file')
      return 'https' if ((old_protocol == 'https') && new_protocol == 'file')
      new_protocol
    end

    def self.parse_and_set_proxy(proxy)
      if proxy.downcase == 'localhost'
        @@host = 'localhost'
        @@port = proxy.split(':').last
      else
        parts = proxy.split(':')
        @@port = parts.delete_at(-1)
        @@host = parts.join(':')
        if (@@host == nil || @@port == nil)# !@@host =~ /^http/)
          puts "Invalid proxy specification..."
          puts "neither host nor port can be nil!"
          exit
        end
      end
      puts "[ACTION] Setting proxy: host=<#{@@host}>, port=<#{@@port}>"
      @@agent.set_proxy(@@host, @@port)
    end

    def self.parse_and_set_basic_auth(basic_auth)
      login, pass = basic_auth.split('@')
      puts "[ACTION] Basic authentication: login=<#{login}>, pass=<#{pass}>"
      @@agent.basic_auth(login, pass)
    end

    def self.set_user_agent(user_agent)
      #puts "[ACTION] Setting user-agent to #{user_agent}"
      @@agent.user_agent = user_agent
    end

    def self.handle_relative_path(doc_url)
      if @@base_dir == nil
        @@base_dir = doc_url.scan(/.+\//)[0] if @@current_doc_protocol == 'file'
      else
        @@current_doc_url = ((@@base_dir + doc_url) if doc_url !~ /#{@@base_dir}/)
      end
    end

    def self.store_host_name(doc_url)
      @@host_name = 'http://' + @@mechanize_doc.uri.to_s.scan(/http:\/\/(.+\/)+/).flatten[0] if @@current_doc_protocol == 'http'
      @@host_name = 'https://' + @@mechanize_doc.uri.to_s.scan(/https:\/\/(.+\/)+/).flatten[0] if @@current_doc_protocol == 'https'
      @@host_name = doc_url if @@host_name == nil
      @@host_name = @@host_name[0..-2] if @@host_name[-1].chr == '/'
      @@original_host_name ||= @@host_name
    end #end of method store_host_name

    def self.handle_relative_url(doc_url, resolve)
      return if doc_url =~ /^http/
      case resolve
        when :full
          @@current_doc_url = (@@host_name + doc_url) if ( @@host_name != nil && (doc_url !~ /#{@@host_name}/))
          @@current_doc_url = @@current_doc_url.split('/').uniq.join('/')
        when :host
          base_host_name = @@host_name.scan(/(http.+?\/\/.+?)\//)[0][0]
          @@current_doc_url = base_host_name + doc_url
        else
          #custom resilving
          @@current_doc_url = resolve + doc_url
      end
    end #end of function handle_relative_url
  end #end of class FetchAction
end #end of module Scrubyt
