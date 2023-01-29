class Array
  # This is a convenience method for creating a Slice from an Array. It is the equivalent
  # of writing:
  #
  # ```
  # Slice.new(array.size) { |idx| array[idx] }
  # ```
  #
  # Use cases are primarily for convenience and readability.
  #
  # ```
  # # In a spec, you need a Slice of 10 elements.
  # [1, 2, 3, 5, 7, 11, 13, 17, 19, 23].to_slice
  #
  # # In a spec, you have a method that is returning an array, but your original
  # # data is in a slice.
  # do_something_and_get_an_array.to_slice.should eq original_slice
  # ```
  #
  def to_slice
    Slice.new(self.size) { |idx| self[idx] }
  end
end
