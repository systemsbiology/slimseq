class Array
  def as_indexed_pairs
    each_with_index {|e,i| [e,i]}
  end
end
