module Scrubyt
  class RegexpFilter < BaseFilter
    
    def evaluate(source)
      if source.is_a? String
        source.scan(@example).flatten
      else
        source.inner_text.scan(@example).flatten
      end    
    end
    
    def to_sexp
      [:lit, @example]
    end
    
  end #End of class TreeFilter
end #End of module Scrubyt
