class Numeric
  def percent_of(other,format="%.2f%%")
    sprintf format, self.to_f/other.to_f*100.0
  end
end
