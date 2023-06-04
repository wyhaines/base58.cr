require "./checksum"
require "./extensions/array"
require "./extensions/string"
require "./extensions/static_array"
require "./alphabet"
require "./pointer_collection"

module Base58
  @[AlwaysInline]
  def self.decode(value : String, check : Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode(value.to_slice.to_unsafe, value.bytesize, check, into, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : String, check : Check, into = String, mutate : Bool = false, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode(value.to_slice.to_unsafe, value.bytesize, check, into, mutate, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Slice(UInt8) | StaticArray(UInt8, N), check : Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    decode(value.to_unsafe, value.size, check, into, alphabet)
  end

  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    String.new(size) do |ptr|
      _, final_size = decode_into_pointer(value, ptr, size, check, alphabet)
      {final_size, final_size}
    end
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    Slice.new(*decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, check, alphabet))
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    static_array = StaticArray(UInt8, N).new(0)
    _, final_size = decode_into_pointer(value, static_array.to_unsafe, size, check, alphabet)
    {static_array, final_size}
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Pointer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, check, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_to_array(value, size, check, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_to_array(value, size, check, alphabet).map(&.chr)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer = StringBuffer.new(size)
    decode(value, size, into: buffer.buffer, check: check, mutate: true, alphabet: alphabet)
    buffer
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    original_size = into.bytesize
    buffer_size = original_size + size + 1
    String.new(buffer_size) do |ptr|
      ptr.copy_from(into.to_slice.to_unsafe, original_size)
      _, final_size = decode_into_pointer(value, ptr + original_size, size, check, alphabet)
      {original_size + final_size, original_size + final_size}
    end
  end

  @[AlwaysInline]
  def self.unsafe_decode(value : Pointer(UInt8), size : Int32, check : Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    _, final_size = decode_into_pointer(value, into.to_slice.to_unsafe, size, check, alphabet)
    header = into.as({Int32, Int32, Int32}*)
    header.value = {String::TYPE_ID, final_size, final_size}
    into
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : String, mutate : Bool = false, alphabet : Alphabet.class = Alphabet::Bitcoin)
    if mutate
      unsafe_decode(value, size, check, into, alphabet)
    else
      decode(value, size, check: check, into: into, alphabet: alphabet)
    end
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : StaticArray(UInt8, N), alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    _, final_size = decode_into_pointer(value, into.to_unsafe, size, check, alphabet)
    {into, final_size}
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    _, final_size = decode_into_pointer(value, into.to_unsafe, size, check, alphabet)
    {into, final_size}
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_pointer(value, into, size, check, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Array(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_array(value, into, size, check, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_array(value, into, size, check, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, check : Check, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode(value, check: check, into: into.buffer, size: size, mutate: true, alphabet: alphabet)
  end

  def self.decode_to_array(value : Pointer(UInt8), size : Int, check : Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr, final_size = decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, check, alphabet)
    Array(UInt8).new(final_size) do |i|
      ptr[i]
    end
  end

  @[AlwaysInline]
  private def self.decode_into_array(value : Pointer(UInt8), array : Array(UInt8), size : Int, check : Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr, final_size = decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, check, alphabet)
    index = 0
    while index < final_size
      array << ptr[index]
      index += 1
    end
    array
  end

  @[AlwaysInline]
  private def self.decode_into_array(value : Pointer(UInt8), array : Array(Char), size : Int, check : Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr, final_size = decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, check, alphabet)
    index = 0
    while index < final_size
      array << ptr[index].chr
      index += 1
    end
    array
  end

  @[AlwaysInline]
  def self.validate_checksum?(pointer, pointer_index, check)
    slice = Slice.new(pointer, pointer_index)
    # payload = slice[..-4] -- this is the payload, but we don't need it
    checksum = slice[-4..]

    case check.type
    when Checksum::Base58Check
      calculate_base58check_checksum("", pointer, pointer_index - 4)
    else
      calculate_cb58_checksum("", pointer, pointer_index - 4)
    end

    if checksum == SHABuffer[0..3]
      true
    else
      nil
    end
  end

  @[AlwaysInline]
  def self.validate_checksum(pointer, pointer_index, check)
    if validate_checksum?(pointer, pointer_index, check)
      true
    else
      raise ChecksumMismatch.new("Checksum Mismatch; expected #{Slice.new(pointer, pointer_index)[-4..].hexstring}, but found #{SHABuffer[0..3].hexstring}")
    end
  end

  # Decodes a Base58 encoded value pointed to by `value` into a pointer `pointer`. The checksum
  # _will be_ in the bytes returned, but the length returned will not include the checksum.
  def self.decode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, check : Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    index = 0
    pointer_index = 0

    _, pointer_index = primary_decoding(value, pointer, size, index, pointer_index, alphabet)
    pointer_index = zero_padding(value, pointer, size, pointer_index, alphabet[0])
    reverse_decoding(pointer, pointer_index)
    validate_checksum(pointer, pointer_index, check)

    {pointer, pointer_index - 4}
  end
end
