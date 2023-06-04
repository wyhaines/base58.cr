class String
  # This string constructor exists to create a new string which is a copy of an existing
  # string, with a separately allocated memory buffer.
  def self.new(string : String)
    new(string.to_slice)
  end

  # This string constructor creates a string of a specific size, without regard to the contents
  # of the string. It is used by the StringBuffer class to create a string which will later
  # mutated, with content inserted.
  def self.new(size : Int)
    new(size) do |_|
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

# A StringBuffer is intended to be used as buffer for strings or binary data. Crystal does not
# permit the String class to be subclassed, so the StringBuffer is implemented as a very light
# wrapper around a String. It works by a String with a specific maximum capacity, which should
# be larger than the largest piece of data that will be stored within it. The string's contents
# will be changed by mutating the string's memory buffer and header information directly,
# avoiding extra copying of data.
#
# ```
# buffer = StringBuffer.new(256)
# buffer.mutate("Hello, world!")
# puts buffer # => "Hello, world!"
#
# buffer << "This is a test."
# puts buffer # => "This is a test."
# ```
#
# The StringBuffer will truncate any data that exceeds the capacity of its underlying string,
# so there is no risk of the string's memory buffer being overrun.
#
class StringBuffer
  getter capacity : Int32
  @buffer : String = ""

  # Initialize the buffer with a String.
  #
  # ```
  # buffer = StringBuffer.new("0x00" * 256)
  # ```
  #
  def initialize(string : String)
    @capacity = string.size
    @buffer = String.new(string)
  end

  # Initialize the buffer with a Slice(UInt8).
  #
  # ```
  # buffer = StringBuffer.new(Slice(UInt8).new(256, 0))
  # ```
  #
  def initialize(slice : Slice(UInt8))
    @capacity = slice.size
    @buffer = String.new(slice)
  end

  # Initialize the buffer with a specific capacity, but do nothing to clear the underlying
  # memory buffer. Until data is assigned to the buffer, it's contents will be undefined
  # and meaningless.
  #
  # ```
  # buffer = StringBuffer.new(256)
  # pp buffer.buffer.to_slice[0, 8] # => Bytes[0, 0, 27, 28, 33, 0, 0, 0]
  # ```
  #
  def initialize(@capacity : Int = 256)
    if capacity = @capacity
      @buffer = String.new(capacity) do |_|
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

  # Shorthand, convenience method for `mutate`.
  @[AlwaysInline]
  def <<(val)
    mutate(val)
  end

  # Returns the underlying String.
  @[AlwaysInline]
  def buffer
    @buffer
  end

  # Outputs the contents of the underlying String to the given IO.
  @[AlwaysInline]
  def to_s(io : IO)
    io << @buffer
  end

  # Returns a Pointer(UInt8) to the underlying String's data. This method is exposed
  # because other internals use it, but it's unlikley that you will want or need to use
  # it directly.
  @[AlwaysInline]
  def to_unsafe
    @buffer.as(UInt8*) + String::HEADER_SIZE
  end

  # Retuns the object header of the underlying String. Like `to_unsafe`, this method
  # is exposed because other internals use it, but it's unlikley that you will want or
  # need to use it directly.
  @[AlwaysInline]
  def header
    @buffer.as({Int32, Int32, Int32}*)
  end

  forward_missing_to @buffer
end
