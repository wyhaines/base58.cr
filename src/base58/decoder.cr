require "./checksum"
require "./extensions/array"
require "./extensions/string"
require "./extensions/static_array"
require "./alphabet"
require "./pointer_collection"

module Base58
  @[AlwaysInline]
  def self.decode(value : String, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode(value.to_slice.to_unsafe, value.bytesize, into, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : String, into = String, mutate : Bool = false, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode(value.to_slice.to_unsafe, value.bytesize, into, mutate, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Slice(UInt8) | StaticArray(UInt8, N), into = String, alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    decode(value.to_unsafe, value.size, into, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Slice(UInt8) | StaticArray(UInt8, N), into : String, mutate : Bool, alphabet : Alphabet.class = Alphabet::Bitcoin)
    if mutate
      unsafe_decode(value.to_slice.to_unsafe, value.bytesize, into, alphabet)
    else
      decode(value, into, alphabet)
    end
  end

  @[AlwaysInline]
  def self.decode(value : Array(UInt8), into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer = GC.malloc_atomic(value.size).as(UInt8*)
    value.each_with_index do |value, i|
      pointer[i] = value
    end
    decode(pointer, value.size, into, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Array(Char), into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer = GC.malloc_atomic(value.size).as(UInt8*)
    value.each_with_index do |value, i|
      pointer[i] = value.ord.to_u8
    end
    decode(pointer, value.size, into, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : StringBuffer, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode(value.buffer, into, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Int.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    result = into.zero
    index = 0
    while index < size
      digit = alphabet.inverse(value[index])
      result = result * 58 + digit
      index += 1
    end
    result
  end

  def self.decode(value : Pointer(UInt8), size : Int32, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    String.new(size) do |ptr|
      _, final_size = decode_into_pointer(value, ptr, size, alphabet)
      {final_size, final_size}
    end
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    Slice.new(*decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, alphabet))
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    static_array = StaticArray(UInt8, N).new(0)
    _, final_size = decode_into_pointer(value, static_array.to_unsafe, size, alphabet)
    {static_array, final_size}
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Pointer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_to_array(value, size, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_to_array(value, size, alphabet).map(&.chr)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer = StringBuffer.new(size)
    decode(value, size, into: buffer.buffer, mutate: true, alphabet: alphabet)
    buffer
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    original_size = into.bytesize
    buffer_size = original_size + size + 1
    bigptr = GC.malloc_atomic(buffer_size * 2).as(UInt8*)
    String.new(buffer_size) do |ptr|
      ptr.copy_from(into.to_slice.to_unsafe, original_size)
      _, final_size = decode_into_pointer(value, ptr + original_size, size, alphabet)
      {original_size + final_size, original_size + final_size}
    end
  end

  @[AlwaysInline]
  def self.unsafe_decode(value : Pointer(UInt8), size : Int32, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    _, final_size = decode_into_pointer(value, into.to_slice.to_unsafe, size, alphabet)
    header = into.as({Int32, Int32, Int32}*)
    header.value = {String::TYPE_ID, final_size, final_size}
    into
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : String, mutate : Bool = false, alphabet : Alphabet.class = Alphabet::Bitcoin)
    if mutate
      unsafe_decode(value, size, into, alphabet)
    else
      decode(value, size, into: into, alphabet: alphabet)
    end
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : StaticArray(UInt8, N), alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    _, final_size = decode_into_pointer(value, into.to_unsafe, size, alphabet)
    {into, final_size}
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    _, final_size = decode_into_pointer(value, into.to_unsafe, size, alphabet)
    {into, final_size}
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_pointer(value, into, size, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Array(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_array(value, into, size, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode_into_array(value, into, size, alphabet)
  end

  @[AlwaysInline]
  def self.decode(value : Pointer(UInt8), size : Int32, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    decode(value, into: into.buffer, size: size, mutate: true, alphabet: alphabet)
  end

  # -----

  def self.decode_to_array(value : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr, final_size = decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, alphabet)
    Array(UInt8).new(final_size) do |i|
      ptr[i]
    end
  end

  @[AlwaysInline]
  private def self.decode_into_array(value : Pointer(UInt8), array : Array(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr, final_size = decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, alphabet)
    index = 0
    while index < final_size
      array << ptr[index]
      index += 1
    end
    array
  end

  @[AlwaysInline]
  private def self.decode_into_array(value : Pointer(UInt8), array : Array(Char), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr, final_size = decode_into_pointer(value, GC.malloc_atomic(size).as(UInt8*), size, alphabet)
    index = 0
    while index < final_size
      array << ptr[index].chr
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
  def self.primary_decoding(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, index : Int, pointer_index : Int, alphabet : Alphabet.class)
    pointer_index = 0
    while index < size
      val = alphabet.inverse(value[index]).to_u16
      inner_idx = 0
      while inner_idx < pointer_index
        byte = pointer[inner_idx]
        val += byte.to_u16 * 58
        pointer[inner_idx] = (val & 0xff).to_u8
        val >>= 8
        inner_idx += 1
      end

      while val > 0
        pointer[pointer_index] = (val & 0xff).to_u8
        pointer_index += 1
        val >>= 8
      end
      index += 1
    end

    {index, pointer_index}
  end

  @[AlwaysInline]
  def self.zero_padding(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, pointer_index : Int, zer0 : UInt8)
    index = 0
    while index < size
      break if value[index] != zer0
      pointer[pointer_index] = 0
      pointer_index += 1
      index += 1
    end

    pointer_index
  end

  @[AlwaysInline]
  def self.reverse_decoding(pointer, pointer_index)
    front_pos = 0
    back_pos = pointer_index - 1
    while front_pos <= back_pos
      pointer[front_pos], pointer[back_pos] = pointer[back_pos], pointer[front_pos]
      front_pos += 1
      back_pos -= 1
    end
  end

  def self.decode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    index = 0
    pointer_index = 0

    index, pointer_index = primary_decoding(value, pointer, size, index, pointer_index, alphabet)
    pointer_index = zero_padding(value, pointer, size, pointer_index, alphabet[0])
    reverse_decoding(pointer, pointer_index)

    {pointer, pointer_index}
  end

  def self.decode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, alphabet : Alphabet::Monero.class)
    pointer_index = 0
    aggregate_index = 0
    aggregate_pointer_index = 0
    ntimes, remainder = size.divmod(11)
    iterations = (remainder.zero? ? ntimes : ntimes + 1)
    iterations.times do |nth_iteration|
      index = aggregate_index
      pointer_index = aggregate_pointer_index
      target_size = index + 11
      target_size = size if target_size > size

      while index < target_size
        val = alphabet.inverse(value[index]).to_u16
        inner_idx = aggregate_pointer_index
        while inner_idx < pointer_index
          byte = pointer[inner_idx]
          val += byte.to_u16 * 58
          pointer[inner_idx] = (val & 0xff).to_u8
          val >>= 8
          inner_idx += 1
        end

        while val > 0
          pointer[pointer_index] = (val & 0xff).to_u8
          pointer_index += 1
          val >>= 8
        end
        index += 1
      end

      zer0 = alphabet[0]

      zeropad_index = aggregate_index
      while zeropad_index < index
        break if value[index] != zer0
        pointer[pointer_index] = 0
        pointer_index += 1
        zeropad_index += 1
      end

      front_pos = aggregate_pointer_index
      back_pos = pointer_index - 1
      while front_pos <= back_pos
        pointer[front_pos], pointer[back_pos] = pointer[back_pos], pointer[front_pos]
        front_pos += 1
        back_pos -= 1
      end

      aggregate_index = index
      aggregate_pointer_index = pointer_index
    end

    {pointer, aggregate_pointer_index}
  end

  struct Decoder
    struct Into
      @into : String.class | String | StringBuffer | Pointer.class | Pointer(UInt8).class | Array(UInt8).class | Array(Char).class | Array(UInt8) | Array(Char) | Slice(UInt8).class | Slice(UInt8)

      def initialize(@into)
      end

      @[AlwaysInline]
      def decode(value, alphabet : Alphabet.class = Alphabet::Bitcoin)
        Base58.decode(value, @into, alphabet)
      end

      @[AlwaysInline]
      def [](value, alphabet : Alphabet.class = Alphabet::Bitcoin)
        decode(value, @into, alphabet)
      end
    end

    @[AlwaysInline]
    def self.[](value)
      Base58.decode(value)
    end

    @[AlwaysInline]
    def self.into(into)
      Into.new(into)
    end

    def self.valid?(value : UInt8, alphabet : Alphabet.class = Alphabet::Bitcoin)
      valid_for({value.chr}, alphabet)
    end

    def self.valid?(value : Char, alphabet : Alphabet.class = Alphabet::Bitcoin)
      valid_for({value}, alphabet)
    end

    def self.valid?(value : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
      valid_for(value.to_slice, alphabet)
    end

    def self.valid?(value : Enumerable, alphabet : Alphabet.class = Alphabet::Bitcoin)
      valid_for(value, alphabet)
    end

    def self.valid?(value : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
      valid_for(value.buffer.to_slice, alphabet)
    end

    def self.valid?(value : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
      valid_for(PointerCollection.new(value, size), alphabet)
    end

    @[AlwaysInline]
    def self.valid_for(value : Enumerable, alphabet)
      value.all? { |byte| alphabet.inverse?(byte) }
    end
  end
end
