struct StaticArray
  # A static array has a fixed size. If a value smaller than the size of the static array is
  # inserted into it, there may be trailing zeros after the data. This method removes those
  # trailing zeros, and optionally any leading zeros, and returns a Slice containing the
  # stripped data.
  #
  # Example:
  #
  # ```
  # ary = StaticArray[0, 1, 2, 3, 4, 0]
  # ary.strip                            # => StaticArray[0, 1, 2, 3, 4]
  # ary.strip(left: false, right: false) # => StaticArray[0, 1, 2, 3, 4, 0]
  # ary.strip(left: true, right: false)  # => StaticArray[1, 2, 3, 4, 0]
  # ary.strip(left: false, right: true)  # => StaticArray[0, 1, 2, 3, 4]
  # ary.strip(left: true)                # => StaticArray[1, 2, 3, 4]
  # ary.strip(left: true, right: true)   # => StaticArray[1, 2, 3, 4]
  #
  def strip(left : Bool = false, right : Bool = true)
    left_limit = 0
    ptr = self.to_unsafe
    if left
      while ptr[left_limit] == 0
        left_limit += 1
      end
    end

    right_limit = self.size - 1
    if right
      while ptr[right_limit] == 0
        right_limit -= 1
      end
    end

    new_size = right_limit - left_limit + 1
    Slice.new(ptr + left_limit, new_size)
  end
end
