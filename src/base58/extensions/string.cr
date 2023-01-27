class String
  def self.new(string : String)
    new(string.to_slice)
  end

  def self.new(size : Int)
    new(size) do |ptr|
      {size, size}
    end
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

  def mutate(val)
    byte_limit = val.bytesize < @capacity ? val.bytesize : @capacity
    char_limit = val.single_byte_optimizable? ? byte_limit : val.byte_slice(0, byte_limit).size
    (@buffer.as(UInt8*) + String::HEADER_SIZE).copy_from(val.to_s.to_slice.to_unsafe, byte_limit)
    header = @buffer.as({Int32, Int32, Int32}*)
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

  forward_missing_to @buffer
end
