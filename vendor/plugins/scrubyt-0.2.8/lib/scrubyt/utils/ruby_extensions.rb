class Module
  def option_reader(key_default_hash)
    key_default_hash.each do |key, default|
      define_method(key) {
        if @options[key].nil?
          if default.is_a? Proc
            instance_eval(&default)
          else
            default
          end
        else
          @options[key]
        end
      }
    end
  end
  
  def option_writer(*keys)
    keys.each do |key|
      define_method("#{key.to_s}=".to_sym) { |value|
        @options[key] = value
      }
    end
  end
  
  def option(key, default=nil, writable=false)
    option_reader(key => default)
    option_writer(key) if writable
  end
  
  def option_accessor(key_default_hash)
    key_default_hash.each do |key, default|
      option(key, default, true)
    end
  end
end

class Range
  def <=>(other)
    self.begin <=> other.begin
  end
  
  def +(amount)
   (self.begin + amount)..(self.end + amount)
  end
  
  def -(amount)
   (self.begin - amount)..(self.end - amount)
  end
end

module Math
  def self.min(a, b)
    a < b ? a : b
  end
  
  def self.max(a, b)
    a > b ? a : b
  end
end

class Array
  def to_sexp
    [:array, *to_sexp_array]
  end
  
  def to_sexp_array
    collect { |element| element.to_sexp }
  end
end

class Hash
  def to_sexp
    [:hash, *to_sexp_array]
  end
  
  def to_sexp_array
    sexp = []
    each { |key, value| sexp.push(key.to_sexp, value.to_sexp) }
    sexp
  end
end

class Symbol
  def to_sexp
    [:lit, self]
  end
end

class String
  def to_sexp
    [:str, self]
  end
end

class TrueClass
  def to_sexp
    [:true]
  end
end

class FalseClass
  def to_sexp
    [:false]
  end
end

class Proc
  alias_method :parse_tree_to_sexp, :to_sexp
  def to_sexp
    [:iter, [:fcall, :lambda], nil, parse_tree_to_sexp[1] ]
  end
end