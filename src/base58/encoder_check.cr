module Base58
  # So, if you are reading this, and want to help, I think that these internals could probably be streamlined
  # more. This is very much just a first draft.

  # Encode a String into a new String, with checksumming. This signature accepts an instance of `Base58::Check`,
  # which is used to specify the prefix byte(s), if any, and the checksum algorithm to use.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, String, alphabet)
  end

  # Encode a String into a new StringBuffer, with checksumming. A StringBuffer is a purpose-built container for a
  # mutable string to be used as a data buffer.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encode a String into a new raw memory buffer, pointed to by a Pointer(UInt8), with checksumming.
  # This method will allocate a section of memory sufficient to hold the encoded string, and will return
  # a tuple containing the pointer to the raw memory buffer and the size of the buffer.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Pointer, alphabet)
  end

  # Encode a String into a new Slice(UInt8), with checksumming. This method will allocate Slice(UInt8) with
  # sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Slice(UInt8), alphabet)
  end

  # Encode a String into a new StaticArray(UInt8, N), with checksumming. This method will allocate a
  # StaticArray(UInt8, N) with sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    encode(value.to_slice, check, StaticArray(UInt8, N), alphabet)
  end

  # Encode a String into a new Array(UInt8), with checksumming. This method will allocate an Array(UInt8)
  # with sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Array(UInt8), alphabet)
  end

  # Encode a String into a new Array(Char), with checksumming. This method will allocate an Array(Char)
  # with sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Array(Char), alphabet)
  end

  # Encode a String into an existing String, with checksumming. Because Strings are immutable, the return
  # value of this method will be a new String containing the contents of the original string with the
  # encoded data concatenated onto the end of it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : String, mutate : Bool = false, alphabet : Alphabet.class = Alphabet::Bitcoin)
    if mutate
      encode(value.to_slice, check, into, mutate, alphabet)
    else
      encode(value.to_slice, check, into, alphabet)
    end
  end

  # Encode a string into an existing String by mutating the original string, with checksumming. The original
  # string much have sufficient capacity to hold the encoded data. This is very fast, but the method is
  # labeled unsafe for a reason. It generally works just fine, so long as the string capacity is adequate,
  # but I can't rule out any possibility of surprises.
  @[AlwaysInline]
  def self.unsafe_encode(value : String, check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    unsafe_encode(value.to_slice, check, into, alphabet)
  end

  # Encode a string into an existing StringBuffer, with checksumming.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encode a string into an Array(UInt8) or Array(Char), with checksumming. The new values will be appended
  # to whatever already exists in the array.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encode a string into an existing memory buffer, pointed to by a Pointer(UInt8), with checksumming. There
  # is assumed to be sufficient space in the buffer to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encodes a string into a buffer composed of either a Slice(UInt8) or a StaticArray(UInt8, _), with
  # checksumming. There is assumed to be sufficient space in the buffer to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StaticArray(UInt8, _) | Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encodes a StringBuffer into any target that a String can be encoded into, with checksumming. If no
  # target is specified, it will default to a String.
  @[AlwaysInline]
  def self.encode(value : StringBuffer, check : Base58::Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.buffer, check, into, alphabet)
  end

  # Encodes an Array(UInt8) into any target that a String can be encoded into, with checksumming. If no
  # target is specified, it will default to a String.
  @[AlwaysInline]
  def self.encode(value : Array(UInt8), check : Base58::Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size + check.prefix.bytesize + 4]? || value.size + check.prefix.bytesize + 4).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte
    end
    encode(Slice.new(ptr, value.size), check, into, alphabet)
  end

  # Encodes an Array(Char) into any target that a String can be encoded into, with checksumming. If no
  # target is specified, it will default to a String.
  @[AlwaysInline]
  def self.encode(value : Array(Char), check : Base58::Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size + check.prefix.bytesize + 4]? || value.size + check.prefix.bytesize + 4).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte.ord.to_u8
    end
    encode(Slice.new(ptr, value.size), check, into, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a new String, with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_string(value.to_unsafe, value.size, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a new StringBuffer, with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer = StringBuffer.new(SizeLookup[value.size + check.prefix.bytesize + 4]? || (value.size + check.prefix.bytesize + 4) * 2)
    encode_into_string(value.to_unsafe, buffer.buffer, value.bytesize, check, alphabet)
    buffer
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated memory buffer, with checksumming. The buffer will have sufficient size to hold the encoded
  # data. This method will return a tuple containing the pointer to the data, and its byte size.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Tuple(Pointer(UInt8), Int32)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.bytesize, check, alphabet)
    {pointer, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Slice, with checksumming. The Slice will have sufficient size to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Slice(UInt8)
    Slice.new(*encode_to_pointer(value.to_unsafe, value.bytesize, check, alphabet))
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated StaticArray, with checksumming. The StaticArray will have sufficient size to hold the encoded data.
  # The method will return a tuple containing the StaticArray and its byte size.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StaticArray(UInt8, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    ary = StaticArray(UInt8, N).new(0)
    _, final_size = encode_into_pointer(value.to_unsafe, ary.to_unsafe, value.size, check, alphabet)

    {ary, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Array(UInt8), with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Array(Char), with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, check, alphabet).map(&.chr)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String, with checksumming. This method actually creates a new String that contains a copy of
  # the contents of the original string, and then concatenates the encoded data to it, and returns the new String.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    original_size = into.bytesize
    buffer_size = SizeLookup[value.size + check.prefix.bytesize + 4]? || (value.size + check.prefix.bytesize + 4) * 2
    size = original_size + buffer_size
    String.new(size) do |ptr|
      ptr.copy_from(into.to_slice.to_unsafe, original_size)
      _, final_size = encode_into_pointer(value.to_unsafe, ptr + original_size, value.size, check, alphabet)
      {original_size + final_size, original_size + final_size}
    end
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String. This method defaults to the safe, non-mutating behavior, where
  # the encoded data is concatenated to the original string, and a new String is returned. If you want to mutate the original string, set `mutate: true`.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : String, mutate : Bool = false, alphabet : Alphabet.class = Alphabet::Bitcoin)
    if mutate
      unsafe_encode(value, check, into, alphabet)
    else
      encode(value, check, into, alphabet)
    end
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing StringBuffer, with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, into.buffer, value.bytesize, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String, with checksumming. This method is unsafe, and will mutate the original string.
  @[AlwaysInline]
  def self.unsafe_encode(value : Slice(UInt8) | StaticArray(UInt, _), check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, into, value.bytesize, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Array(UInt8) or Array(Char), with checksumming. The encoded data is appended to the end of the array,
  # one byte per array element.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_array(value.to_unsafe, into, value.size, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Pointer(UInt8), with checksumming. The pointer is assumed to reference a section of memory large enough
  # to hold the encoded data. The method returns a tuple containing the pointer and the size of the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) : {Pointer(UInt8), Int32}
    encode_into_pointer(value.to_unsafe, into, value.size, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Slice(UInt8), with checksumming. The Slice is assumed to have sufficient space
  # to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) : Slice(UInt8)
    encode_into_pointer(value.to_unsafe, into.to_unsafe, value.size, check, alphabet)
    into
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing StaticArray(UInt8, _), with checksumming. The StaticArray is assumed to have sufficient space
  # to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StaticArray(UInt8, _), alphabet : Alphabet.class = Alphabet::Bitcoin)
    _, final_size = encode_into_pointer(value.to_unsafe, into.to_unsafe, value.size, check, alphabet)
    {into, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) to a new Array(UInt8), with checksumming.
  @[AlwaysInline]
  def self.encode_to_array(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.size, check, alphabet)
    Array(UInt8).new(final_size) do |i|
      pointer[i]
    end
  end

  # Encodes the contents of a memory buffer, referenced by a Pointer(UInt8), into a newly allocated memory buffer, with checksumming.
  @[AlwaysInline]
  def self.encode_to_pointer(value : Pointer(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin) : {Pointer(UInt8), Int32}
    buffer_size = SizeLookup[size + check.prefix.bytesize + 4]? || (size + check.prefix.bytesize + 4) * 2
    ptr = GC.malloc_atomic(buffer_size).as(UInt8*)
    encode_into_pointer(value, ptr, size, check, alphabet)
  end

  # Encodes the contents of a memory buffer, referenced by a Pointer(UInt8), into a newly allocated String, with checksumming.
  @[AlwaysInline]
  def self.encode_to_string(value : Pointer(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin) : String
    buffer_size = SizeLookup[size + check.prefix.bytesize + 4]? || (size + check.prefix.bytesize + 4) * 2
    String.new(buffer_size) do |ptr|
      _, final_size = encode_into_pointer(value, ptr, size, check, alphabet)
      {final_size, final_size}
    end
  end

  # This encodes the contents of a memory buffer referenced by a Pointer(UInt8) into another existing memory buffer, with checksumming. All non-Monero, non-Integer
  # checksummed encoding eventually ends up with this method.
  private def self.encode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    checksum_ptr, _ = Checksum.calculate(check, value, size)

    index = 0
    prefix_slice = check.prefix.to_slice

    { {prefix_slice.to_unsafe, check.prefix.bytesize}, {value, size}, {checksum_ptr, check.checksum_length} }.each do |vptr, vsize|
      index = primary_encoding(vptr, pointer, vsize, index)
    end

    { {prefix_slice.to_unsafe, check.prefix.bytesize}, {value, size}, {checksum_ptr, check.checksum_length} }.each do |vptr, vsize|
      index = zero_padding(vptr, pointer, vsize, index)
    end

    reverse_encoding(pointer, index, alphabet)

    pointer[index] = 0
    {pointer, index}
  end

  # This method takes a memory buffer referenced by a Pointer(UInt8), and encodes it into an existing Array(UInt8), with Base58Check.
  @[AlwaysInline]
  private def self.encode_into_array(value : Pointer(UInt8), array : Array(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value, size, check, alphabet)
    index = 0
    while index < final_size
      array << pointer[index]
      index += 1
    end

    array
  end

  # This method takes a memory buffer referenced by a Pointer(UInt8), and encodes it into an existing Array(Char), with Base58Check.
  @[AlwaysInline]
  private def self.encode_into_array(value : Pointer(UInt8), array : Array(Char), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value, size, check, alphabet)
    index = 0
    while index < final_size
      array << pointer[index].chr
      index += 1
    end

    array
  end

  # This method takes a memory buffer referenced by a Pointer(UInt8), and encodes it into an existing String, with checksumming.
  @[AlwaysInline]
  private def self.encode_into_string(value : Pointer(UInt8), string : String, size : Int, check : Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    _, final_size = encode_into_pointer(value, (string.as(UInt8*) + String::HEADER_SIZE), size, check, alphabet)
    header = string.as({Int32, Int32, Int32}*)
    header.value = {String::TYPE_ID, final_size, final_size}
    string
  end
end
