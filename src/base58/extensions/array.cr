class Array
  def to_slice
    Slice.new(self.size) { |idx| self[idx] }
  end
end
