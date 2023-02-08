class String
  def self.new(string : String)
    new(string.to_slice)
  end

  def self.new(size : Int)
    new(size) do |ptr|
      {size, size}
    end
  end

  # This will return the allocated capacity of the string. This number is not normally interesting on its own,
  # in a world where Crystal's string immutability is honored. If, however, one is mutating strings, knowing
  # the capacity of the string becomes important.
  # :nodoc:
  def capacity
    @capacity
  end
end

# This provides a very efficient reusable StringBuffer.
class StringBuffer
  getter capacity : Int32
  @buffer : String = ""

  def initialize(string : String)
    @capacity = string.size
    @buffer = String.new(string)
  end

  def initialize(string : Slice(UInt8))
    @capacity = string.size
    @buffer = String.new(string)
  end

  def initialize(@capacity : Int = 256)
    if capacity = @capacity
      @buffer = String.new(capacity) do |ptr|
        {capacity, capacity}
      end
    end
  end

  # This method takes a memory buffer referenced by a Pointer(UInt8), and encodes it into an existing String. It may be useful to understand how
  # this works, however, so pull up a chair and a drink, dear reader, and we'll have a short chat.
  #
  # A String, in Crystal, is represented by four in-memory pieces of data. These are a Type ID, a byte size, a character size, and the bytes of
  # data that comprise the actual string.
  #
  # `| Type ID | Byte Size | Character Size | Bytes |`
  #
  # The first three of those, taken together, represent the String header. The String class holds an
  # [undocumented constant](https://github.com/crystal-lang/crystal/blob/29f9ac503/src/string.cr#L142), `String::HEADER_SIZE`,
  # which is the size of the header, in bytes.
  #
  # When a String is initially created, a memory buffer of `HEADER_SIZE + capacity` is allocated, where `capacity` is the maximum number
  # of bytes that the String can hold.
  #
  # The `HEADER_SIZE` is used as an offset into this buffer to point to the part of the buffer which will hold the bytes of string data,
  # and that data is inserted into memory starting with that offset.
  #
  # To finalize the String's memory buffer, a header is written into the first `HEADER_SIZE` bytes of the buffer, which contains the
  # Type ID, the byte size, and the character size of the string.
  #
  # Because this is just data in memory, it is possible to access it directly, and manipulate it. Also, a String still works just fine if
  # the allocated memory for it is larger than what is actually used to store the header plus the string data. This provides an opportunity
  # to directly mutate a String.
  #
  # If the data after the `HEADER_SIZE` offset is changed, the string is changed. However, if the amount of data changes, the header must
  # also be updated to reflect the new size of the string. That header is just bytes, though, so it can be rewritten.
  #
  # ```
  # header = string.as({Int32, Int32, Int32}*)                          # Effectively extracts the header from the String as a Pointer({Int32, Int32, Int32}).
  # header.value = {String::TYPE_ID, new_byte_size, new_character_size} # Rewrites the header. MUST NOT exceed original byte_size.
  # ```
  #
  # As mentioned in the comments above, the new data that is inserted into the buffer must not exceed it's original size. If it does,
  # at best, something else might come along later and stomp on that data, but more likely, the program will crash:
  #
  # ```
  # Invalid memory access (signal 11) at address 0x168b0ae
  # ```
  #
  # This limitation is because the `GC.realloc` call, which can be used to resize an allocation to a smaller or a larger size, does not
  # guarantee that, in the case of a larger allocation, the allocation will remain in the same location. If the memory does not have enough
  # free space to increase the size of the allocation, `realloc` will copy the contents of the old buffer to the new location, and then
  # free the old location. If this happens, however, your program's other code won't realize that the string is now in a different location,
  # and when an effort to access it happens, it will access the old location, which will no longer be valid, likely resulting in your program
  # crashing.
  #
  # So... don't do that. Within the limitation regarding not exceeding the original size of the String, however, it appears to work flawlessly.
  def mutate(val)
    byte_limit = val.bytesize < @capacity ? val.bytesize : @capacity
    char_limit = val.single_byte_optimizable? ? byte_limit : val.byte_slice(0, byte_limit).size
    to_unsafe.copy_from(val.to_s.to_slice.to_unsafe, byte_limit)
    header.value = {String::TYPE_ID, byte_limit, char_limit}

    @buffer
  end

  @[AlwaysInline]
  def <<(val)
    mutate(val)
  end

  @[AlwaysInline]
  def buffer
    @buffer
  end

  @[AlwaysInline]
  def to_s(io : IO)
    io << @buffer
  end

  @[AlwaysInline]
  def to_unsafe
    @buffer.as(UInt8*) + String::HEADER_SIZE
  end

  @[AlwaysInline]
  def header
    @buffer.as({Int32, Int32, Int32}*)
  end

  forward_missing_to @buffer
end
