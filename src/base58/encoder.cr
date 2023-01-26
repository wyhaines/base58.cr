require "./extensions/char"
require "./extensions/string"
require "./extensions/slice"
require "./alphabet"
require "digest/sha256"

module Base58
  # So, if you are reading this, and want to help, I think that these internals could probably be streamlined
  # more. This is very much just a first draft.

  private CheckBuffer = Bytes.new(32)

  private SHAEngine1 = Digest::SHA256.new
  private SHAEngine2 = Digest::SHA256.new

  # This is a lookup table for the maximum size of an encoded string, given the number of bytes to encode.
  # It encodes lengths up to 1024 characters, though it would be silly to encode a 1024 byte chunk. It would be
  # vastly faster to break long strings into small chunks and to encode each of the small chunks separately, padding them
  # as necessary to ensure a consistent output size, before concatenating the results. Doind 256 4-byte encodings
  # will be much faster than a single 1024 byte chunk. But...you do you. The library will encode anything that you throw
  # at it.
  {% begin %}
  SizeLookup = begin
    Int32.static_array(0,{% for i in (1..1024) %}{{ (1.365658237309761 * i + 2) }}.to_u32,{% end %})
  end
  {% end %}

  # When encoding integers, do a direct mathematical calculation of the size of the output.
  @[AlwaysInline]
  private def self.calculate_size_for_int(value : Int)
    return 1 if value.zero?

    Math.log(value, 58).to_i + 1
  end

  # Encode an integer into a string, taking an optional alphabet, and an option check encoding flag. This is the default behavior
  # if passed an integer with no other parameters.
  @[AlwaysInline]
  def self.encode(value : Int, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_string(value, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_pointer(value, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    Slice.new(*encode_to_pointer(value, alphabet))
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    size = calculate_size_for_int(value)
    ary = StaticArray(UInt8, N).new(0)
    encode_into_pointer(value, ary.to_unsafe, size, alphabet)

    ary
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet).map(&.chr)
  end

  def self.encode(value : Int, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    new_size = calculate_size_for_int(value)
    original_size = into.bytesize
    size = original_size + new_size
    String.new(size) do |ptr|
      ptr.copy_from(into.to_slice.to_unsafe, original_size)
      encode_into_pointer(value, ptr + original_size, new_size, alphabet)
      {size, size}
    end
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value, into.buffer, calculate_size_for_int(value), alphabet)
    into.buffer
  end

  @[AlwaysInline]
  def self.unsafe_encode(value : Int, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value, into, calculate_size_for_int(value), alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_array(value, into, calculate_size_for_int(value), alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value, into, calculate_size_for_int(value), alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Int, into : StaticArray(UInt8, _) | Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value, into.to_unsafe, calculate_size_for_int(value), alphabet)
    into
  end

  @[AlwaysInline]
  def self.encode(value : String, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, String, alphabet)
  end

  def self.encode(value : String, check : Base58::Check, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, String, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Pointer, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Slice(UInt8), alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    encode(value.to_slice, StaticArray(UInt8, N), alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Array(UInt8), alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Array(Char), alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  @[AlwaysInline]
  def self.unsafe_encode(value : String, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    unsafe_encode(value.to_slice, into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, into : StaticArray(UInt8, _) | Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  def self.encode(value : StringBuffer, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.buffer, into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Array(UInt8), into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size]? || value.size).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte
    end
    encode(Slice.new(ptr, value.size), into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Array(UInt8), check : Base58::Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size + check.prefix.bytesize + 4]? || value.size + check.prefix.bytesize + 4).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte
    end
    encode(Slice.new(ptr, value.size), into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Array(Char), into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size]? || value.size).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte.ord.to_u8
    end
    encode(Slice.new(ptr, value.size), into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Array(Char), check : Base58::Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size + check.prefix.bytesize + 4]? || value.size + check.prefix.bytesize + 4).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte.ord.to_u8
    end
    encode(Slice.new(ptr, value.size), into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_string(value.to_unsafe, value.size, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_string(value.to_unsafe, value.size, check, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer = StringBuffer.new(SizeLookup[value.size]? || value.size * 2)
    encode_into_string(value.to_unsafe, buffer.buffer, value.bytesize, alphabet)
    buffer
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StringBuffer.class, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer = StringBuffer.new(SizeLookup[value.size + check.prefix.bytesize + 4]? || (value.size + check.prefix.bytesize + 4) * 2)
    encode_into_string(value.to_unsafe, buffer.buffer, value.bytesize, alphabet)
    buffer
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Tuple(Pointer(UInt8), Int32)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.bytesize, alphabet)
    {pointer, final_size}
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Slice(UInt8)
    Slice.new(*encode_to_pointer(value.to_unsafe, value.bytesize, alphabet))
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StaticArray(UInt8, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    ary = StaticArray(UInt8, N).new(0)
    _, final_size = encode_into_pointer(value.to_unsafe, ary.to_unsafe, value.size, alphabet)

    {ary, final_size}
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet).map(&.chr)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    original_size = into.bytesize
    buffer_size = SizeLookup[value.size]? || value.size * 2
    size = original_size + buffer_size
    String.new(size) do |ptr|
      ptr.copy_from(into.to_slice.to_unsafe, original_size)
      _, final_size = encode_into_pointer(value.to_unsafe, ptr + original_size, value.size, alphabet)
      {original_size + final_size, original_size + final_size}
    end
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    original_size = into.bytesize
    buffer_size = SizeLookup[value.size + check.prefix.bytesize + 4]? || (value.size + check.prefix.bytesize + 4) * 2
    size = original_size + buffer_size
    String.new(size) do |ptr|
      ptr.copy_from(into.to_slice.to_unsafe, original_size)
      _, final_size = encode_into_pointer(value.to_unsafe, ptr + original_size, value.size, alphabet)
      {original_size + final_size, original_size + final_size}
    end
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : String, mutate : Bool, alphabet : Alphabet.class = Alphabet::Bitcoin)
    if mutate
      unsafe_encode(value, into, alphabet)
    else
      encode(value, into, alphabet)
    end
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, into.buffer, value.bytesize, alphabet)
  end

  @[AlwaysInline]
  def self.unsafe_encode(value : Slice(UInt8) | StaticArray(UInt, _), into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, into, value.bytesize, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_array(value.to_unsafe, into, value.size, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value.to_unsafe, into, value.size, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StaticArray(UInt8, _) | Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value.to_unsafe, into.to_unsafe, value.size, alphabet)
    into
  end

  # -----

  @[AlwaysInline]
  def self.encode_to_array(value : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    size = calculate_size_for_int(value)
    pointer, _ = encode_to_pointer(value, alphabet)
    Array(UInt8).new(size) do |i|
      pointer[i]
    end
  end

  def self.encode_to_array(value : Slice(UInt8) | StaticArray(UInt8, _), alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.size, alphabet)
    Array(UInt8).new(final_size) do |i|
      pointer[i]
    end
  end

  @[AlwaysInline]
  def self.encode_to_pointer(value : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    size = calculate_size_for_int(value)
    ptr = GC.malloc_atomic(size).as(UInt8*)
    encode_into_pointer(value, ptr, size, alphabet)
  end

  @[AlwaysInline]
  def self.encode_to_pointer(value : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    index = 0
    buffer_size = SizeLookup[size]? || size * 2
    ptr = GC.malloc_atomic(buffer_size).as(UInt8*)
    encode_into_pointer(value, ptr, size, alphabet)
  end

  @[AlwaysInline]
  def self.encode_to_pointer(value : Pointer(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    index = 0
    buffer_size = SizeLookup[size + check.prefix.bytesize + 4]? || (size + check.prefix.bytesize + 4) * 2
    ptr = GC.malloc_atomic(buffer_size).as(UInt8*)
    encode_into_pointer(value, ptr, size, alphabet)
  end

  @[AlwaysInline]
  def self.encode_to_string(value : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    size = calculate_size_for_int(value)
    String.new(size) do |ptr|
      encode_into_pointer(value, ptr, size, alphabet)
      {size, size}
    end
  end

  @[AlwaysInline]
  def self.encode_to_string(value : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer_size = SizeLookup[size]? || (size) * 2
    String.new(buffer_size) do |ptr|
      _, final_size = encode_into_pointer(value, ptr, size, alphabet)
      {final_size, final_size}
    end
  end

  @[AlwaysInline]
  def self.encode_to_string(value : Pointer(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer_size = SizeLookup[size + check.prefix.bytesize + 4]? || (size + check.prefix.bytesize + 4) * 2
    String.new(buffer_size) do |ptr|
      _, final_size = encode_into_pointer(value, ptr, size, check, alphabet)
      {final_size, final_size}
    end
  end

  # ===== These are dangerous and are thus restricted to internal use =====

  @[AlwaysInline]
  private def self.encode_into_pointer(value : Int, pointer : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    i = size - 1
    if value == 0
      pointer[0] = alphabet[0]
      return {pointer, 1}
    end

    while value > 0
      value, remainder = value.divmod(58)
      pointer[i] = alphabet[remainder]
      i -= 1
    end

    {pointer, size}
  end

  private def self.encode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    index = primary_encoding(value, pointer, size, 0)
    index = zero_padding(value, pointer, size, index)
    reverse_encoding(pointer, index, alphabet)

    pointer[index] = 0
    {pointer, index}
  end

  private def self.encode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    case check.type
    when Base58::Checksum::Base58Check
      calculate_base58check_checksum(check.prefix, value, size)
    else
      calculate_cb58_checksum(check.prefix, value, size)
    end

    index = 0
    prefix_slice = check.prefix.to_slice

    { {prefix_slice.to_unsafe, check.prefix.bytesize}, {value, size}, {CheckBuffer.to_unsafe, 4} }.each do |vptr, vsize|
      index = primary_encoding(vptr, pointer, vsize, index)
    end

    not_finished_zero_padding = true
    { {prefix_slice.to_unsafe, check.prefix.bytesize}, {value, size}, {CheckBuffer.to_unsafe, 4} }.each do |vptr, vsize|
      index = zero_padding(vptr, pointer, vsize, index)
    end

    reverse_encoding(pointer, index, alphabet)

    pointer[index] = 0
    {pointer, index}
  end

  private def self.encode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, alphabet : Alphabet::Monero.class)
    zer0 = alphabet[0]
    aggregate_index = 0
    aggregate_byte_pos = 0
    ntimes, remainder = size.divmod(8)
    iterations = (remainder.zero? ? ntimes : ntimes + 1)
    iterations.times do |nth_iteration|
      index = aggregate_index
      byte_pos = aggregate_byte_pos
      target_size = byte_pos + 8
      target_size = size if target_size > size

      while byte_pos < target_size
        carry = value[byte_pos].to_u16
        inner_idx = aggregate_index
        while inner_idx < index
          byte = pointer[inner_idx]
          carry += byte.to_u16 << 8
          pointer[inner_idx] = (carry % 58).to_u8
          carry //= 58
          inner_idx += 1
        end

        while carry > 0
          pointer[index] = (carry % 58).to_u8
          index += 1
          carry //= 58
        end
        byte_pos += 1
      end

      byte_pos = aggregate_byte_pos
      while byte_pos < target_size
        break if value[byte_pos] != 0
        pointer[index] = 0
        byte_pos += 1
        index += 1
      end

      front_pos = aggregate_index
      back_pos = index - 1
      while front_pos <= back_pos
        pointer[front_pos], pointer[back_pos] = alphabet[pointer[back_pos]], alphabet[pointer[front_pos]]
        front_pos += 1
        back_pos -= 1
      end

      pad_limit = (nth_iteration == iterations - 1 ? SizeLookup[remainder] - 1 : 11)
      while index < pad_limit
        pointer[index] = zer0
        index += 1
      end

      aggregate_index = index
      aggregate_byte_pos += 8
    end

    {pointer, aggregate_index}
  end

  @[AlwaysInline]
  private def self.encode_into_array(value : Int, array : Array(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, _ = encode_to_pointer(value, alphabet)
    index = 0
    while index < size
      array << pointer[index]
      index += 1
    end

    array
  end

  @[AlwaysInline]
  private def self.encode_into_array(value : Pointer(UInt8), array : Array(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value, size, alphabet)
    index = 0
    while index < final_size
      array << pointer[index]
      index += 1
    end

    array
  end

  @[AlwaysInline]
  private def self.encode_into_array(value : Int, array : Array(Char), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, _ = encode_to_pointer(value, alphabet)
    index = 0
    while index < size
      array << pointer[index].chr
      index += 1
    end

    array
  end

  @[AlwaysInline]
  private def self.encode_into_array(value : Pointer(UInt8), array : Array(Char), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value, size, alphabet)
    index = 0
    while index < final_size
      array << pointer[index].chr
      index += 1
    end

    array
  end

  @[AlwaysInline]
  private def self.encode_into_string(value : Int, string : String, size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value, (string.as(UInt8*) + String::HEADER_SIZE), size, alphabet)
    header = string.as({Int32, Int32, Int32}*)
    header.value = {String::TYPE_ID, size, size}
    string
  end

  @[AlwaysInline]
  private def self.encode_into_string(value : Pointer(UInt8), string : String, size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    _, final_size = encode_into_pointer(value, (string.as(UInt8*) + String::HEADER_SIZE), size, alphabet)
    header = string.as({Int32, Int32, Int32}*)
    header.value = {String::TYPE_ID, final_size, final_size}
    string
  end

  # Helper method so that the logic involved in primary encoding doesn't have to be repeated multiple times.
  @[AlwaysInline]
  private def self.primary_encoding(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, index : Int = 0)
    byte_pos = 0
    while byte_pos < size
      carry = value[byte_pos].to_u16
      inner_idx = 0
      while inner_idx < index
        byte = pointer[inner_idx]
        carry += byte.to_u16 << 8
        pointer[inner_idx] = (carry % 58).to_u8
        carry //= 58
        inner_idx += 1
      end

      while carry > 0
        pointer[index] = (carry % 58).to_u8
        index += 1
        carry //= 58
      end
      byte_pos += 1
    end

    index
  end

  # Helper method so that the logic involved in zero padding is not repeated multiple times.
  @[AlwaysInline]
  private def self.zero_padding(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, index : Int = 0)
    byte_pos = 0
    while byte_pos < size
      break if value[byte_pos] != 0
      pointer[index] = 0
      byte_pos += 1
      index += 1
    end

    index
  end

  # Helper method so that the logic involved in reversing the encoding is not repeated multiple times.
  @[AlwaysInline]
  private def self.reverse_encoding(pointer, index, alphabet)
    front_pos = 0
    back_pos = index - 1
    while front_pos <= back_pos
      pointer[front_pos], pointer[back_pos] = alphabet[pointer[back_pos]], alphabet[pointer[front_pos]]
      front_pos += 1
      back_pos -= 1
    end
  end

  private def self.calculate_base58check_checksum(prefix, value, size)
    SHAEngine1 << prefix
    SHAEngine1 << Slice.new(value, size)
    SHAEngine2 << SHAEngine1.final
    SHAEngine2.final(CheckBuffer)
    SHAEngine1.reset
    SHAEngine2.reset
  end

  private def self.calculate_cb58_checksum(prefix, value, size)
    SHAEngine1 << prefix
    SHAEngine1 << Slice.new(value, size)
    SHAEngine1.final(CheckBuffer)
    SHAEngine1.reset
  end

  struct Encoder
    struct Into
      @into : String.class | String | StringBuffer | StringBuffer.class | Pointer.class | Pointer(UInt8).class | Array(UInt8).class | Array(Char).class | Array(UInt8) | Array(Char) | Slice(UInt8).class | Slice(UInt8)

      def initialize(@into)
      end

      @[AlwaysInline]
      def encode(value, alphabet : Alphabet.class = Alphabet::Bitcoin)
        Base58.encode(value, @into, alphabet)
      end

      @[AlwaysInline]
      def [](value, alphabet : Alphabet.class = Alphabet::Bitcoin)
        encode(value, @into, alphabet)
      end
    end

    @[AlwaysInline]
    def self.[](value)
      Base58.encode(value)
    end

    @[AlwaysInline]
    def self.into(into)
      Into.new(into)
    end
  end
end
