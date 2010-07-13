module ApiAccessible
  
  def api_reader(*syms)
    syms.flatten.each do |s|
      @@api_methods ||= Array.new
      @@api_methods << s.to_sym
    end
  end

  def api_methods
    @@api_methods ||= Array.new
  end

end
