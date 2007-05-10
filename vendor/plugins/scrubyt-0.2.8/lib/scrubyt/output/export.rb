module Scrubyt
  # =<tt>exporting previously defined extractors</tt>
  class Export
    ##
    #Exports the given extractor (specified by it's root pattern) from the given file
    #
    #_input_file_ - the full path of the file where the extractor was defined. This can
    #be achieved by calling 
    # 
    #  pattern.export(__File__)
    # 
    #from the file of the extractor definition.
    # 
    #*parameters*
    # 
    #_root_pattern_ - the root pattern of the extractor. This is the variable 'something' in
    #such a call:
    # 
    #  something = Scrubyt::Extractor.define ...
    #  
    #However, since the export method should not be called directly (pattern is calling 
    #it), you will probably never need to care about this parameter.
    #
    #_output_file_name_ - the name of the file where the exported extractor should be 
    #dumped; From default (i.e. if you don't specify this parameter) this is 
    #"#{wrapper_name}_extractor_export.rb". You may override this setting if specifying
    #this optional parameter.
    #
    #_extractor_result_file_name_ - the name of the file, where the result of the 
    #*exported* extractor should be dumped - for example, if _output_file_name_ is "foo.rb"
    #and _extractor_result_file_name_ is "bar.xml", the extractor is exported to a file named
    #"foo.rb", and after running "foo.rb", the results will be dumped to the file "bar.xml"
    #If this option is not specified, the result is dumped to standard output as XML.
    #
    #Examples:
    #
    #  camera_data = Scrubyt::Extractor.define do
    #    Action.fetch File.join(File.dirname(__FILE__), "input.html")
    #    
    #    P.item_name "Canon EOS 20D SLR Digital Camera (Lens sold separately)"
    #  end
    #  
    #  camera_data.export(__FILE__)
    #  
    #This will export this extractor to a file called "camera_data_extractor_export.rb". 
    #If "camera_data_extractor_export.rb" will be executed, the result will be dumped
    #to the standard output.
    #  
    #Note that the export method in the last line belongs to the class Scrubyt::Pattern
    #and not to Scrubyt::Export (i.e. this class). Scrubyt::Pattern.export will call 
    #Scrubyt::Export.export.
    #
    #  camera_data = Scrubyt::Extractor.define do
    #    Action.fetch File.join(File.dirname(__FILE__), "input.html")
    #    
    #    P.item_name "Canon EOS 20D SLR Digital Camera (Lens sold separately)"
    #  end
    #  
    #  camera_data.export(__FILE__, 'my_super_camera_extractor.rb', '/home/peter/stuff/result.xml')
    #  
    #This snippet will export the extractor to a file named 'my_super_camera_extractor.rb'.
    #After running 'my_super_camera_extractor.rb', the result will be dumped to the file
    #'/home/peter/stuff/result.xml'.
    def self.export(root_pattern, wrapper_name, output_file_name=nil, extractor_result_file_name=nil)
      sexp = [:block]
      sexp << export_header(wrapper_name)
      sexp << export_extractor(root_pattern, wrapper_name)
      sexp << export_footer(wrapper_name, extractor_result_file_name)
      
      result = RubyToRuby.new.process(sexp)
      result.gsub! '"' + root_pattern.source_file + '"', '__FILE__'

      output_file_name ||= "#{wrapper_name}_extractor_export.rb"
      output_file = open(output_file_name, 'w')
      output_file.write(result)      
      output_file.close
      result
    end

private
    def self.create_sexp(code)
      (ParseTree.new.parse_tree_for_string(code))[0]
    end

    def self.export_header(wrapper_name)
      create_sexp "require 'rubygems'; require 'scrubyt'"
    end
    
    def self.export_footer(wrapper_name, extractor_result_file_name)
      if extractor_result_file_name
        create_sexp "#{wrapper_name}.to_xml.write(open('result_of_exported_extractor.xml', 'w'), 1)"
      else
        create_sexp "#{wrapper_name}.to_xml.write($stdout, 1)"
      end
    end
    
    def self.export_extractor(root_pattern, wrapper_name)
      # filter actions before and after pattern
      pre_pattern_sexp = []
      post_pattern_sexp = []
      pattern_skipped = false
      actions = ['next_page', *NavigationActions::KEYWORDS]
      
      root_pattern.source_proc.to_sexp[3][1..-1].each do |sexp|
        get_call = lambda { |sexp|
          if sexp[0] == :fcall
            return sexp[1].to_s
          elsif sexp[0] == :iter || sexp[0] == :call
            return get_call.call(sexp[1])
          else
            return nil
          end
        }
        call = get_call.call(sexp)
        if(call.nil? || actions.index(call) != nil)
          if !pattern_skipped
            pre_pattern_sexp.push(sexp)
          else
            post_pattern_sexp.push(sexp)
          end
        else
          raise "Second pattern tree found while exporting." if pattern_skipped
          pattern_skipped = true
        end
      end

      # build extractor content
      inner_block = [:block]
      inner_block.push([:block, *pre_pattern_sexp])
      inner_block.push([:block, export_pattern(root_pattern)])
      inner_block.push([:block, *post_pattern_sexp])
      
      # build extractor
      [:block, [:lasgn, wrapper_name, [:iter, [:call, [:colon2, [:const, :Scrubyt], :Extractor], :define], nil, inner_block]]]
    end    
    
    def self.export_pattern(root_pattern)
      root_pattern.children[0].to_sexp
    end
  end
end
