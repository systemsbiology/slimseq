module Scrubyt
  ##
  #=<tt>Build URIs from different parameters</tt>
  #
  #When crawling to further pages which are machine-generated
  #(most typically "next" pages) we need to detect the pattern
  #and generate the next URI based on the edetected rule. This
  #class provides methods to build URIs based on different criteria.
  #
  #The other possibility is to use constant objects ('Next' links,
  #or image links (like right arrow) pointing to the next page).
  #URIBUilder supports both possibilities.
  class URIBuilder
    attr_reader :next_page_example, :next_page_pattern, :limit, :next_param, :next_increment, :increment, :current_uri
    
    def initialize(pattern,args)
      if args[0] =~ /^http.+/
        #Figure out how are the URLs generated based on the next URL
        get_next_param(string_diff(args[0], args[1]))
        @increment = 0
        @current_uri = args[1]
        @limit = args[2][:limit] if args.size > 2
      else
        #Otherwise, do this in the 'classic' way (by clicking on the "next" link)
        @next_page_pattern = pattern
        @next_page_example = args[0]
        @limit = args[1][:limit] if args.size > 1
      end
    end
    
    #Used when generating the next URI (as opposed to 'clicking' the next link)
    def generate_next_uri      
      @increment += @next_increment
      return @current_uri if @increment == @next_increment
      @next_increment = 1 if @next_increment == 2
      if @current_uri !~ /#{@next_param}/
        @current_uri += (@next_param + '=' + @next_increment.to_s)
      else
        @current_uri = @current_uri.sub(/#{@next_param}=#{@increment-@next_increment}/) do
          "#{@next_param}=#{@increment}"
        end
      end
    end 
    
private
    def get_next_param(pair)
      param_and_value = pair.split('=')
      @next_param = param_and_value[0]
      @next_increment = param_and_value[1].to_i
    end
    
    def find_difference_index(s1,s2)
      cmp = s2.scan(/./).zip(s1.scan(/./))    
      i = 0
      loop do
        return i if cmp[i][0] != cmp[i][1]
        i+=1
      end
    end

    def string_diff(s1,s2)
      s2[find_difference_index(s1, s2)..s2.size-find_difference_index(s1.reverse, s2.reverse)-1]
    end #end of method string_diff
  end #end of class URIBuilder
end #end of module Scrubyt 


