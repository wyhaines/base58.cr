struct StaticArray
  def strip
    left_limit = 0
    ptr = self.to_unsafe
    # while ptr[left_limit] == 0
    #   left_limit += 1
    # end

    right_limit = self.size - 1
    while ptr[right_limit] == 0
      right_limit -= 1
    end

    new_size = right_limit - left_limit + 1
    Slice.new(ptr + left_limit, new_size)
  end
end
