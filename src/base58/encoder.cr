# require "./extensions/char"
require "./extensions/string"
require "./alphabet"
require "digest/sha256"

module Base58
  # So, if you are reading this, and want to help, I think that these internals could probably be streamlined
  # more. This is very much just a first draft.

  # This is a preallocated buffer for calculating Base58Check / CB58 checksums. This implementation,
  # without any sort of mutex/locking, is NOT threadsafe. TODO would be to make it so.
  private CheckBuffer = Bytes.new(32)

  # SHAEngine1 and SHAEngine2 are preallocated classes for handling checksumming.
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

  # Encode an integer into a string, taking an optional alphabet.
  @[AlwaysInline]
  def self.encode(value : Int, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_string(value, alphabet)
  end

  # Encode an integer into a new raw allocation of memory, returning a pointer to the memory buffer,
  # and the size of the buffer.
  @[AlwaysInline]
  def self.encode(value : Int, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_pointer(value, alphabet)
  end

  # Encode an integer into a new Slice.
  @[AlwaysInline]
  def self.encode(value : Int, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    Slice.new(*encode_to_pointer(value, alphabet))
  end

  # Encode an integer into a new StaticArray.
  @[AlwaysInline]
  def self.encode(value : Int, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    size = calculate_size_for_int(value)
    ary = StaticArray(UInt8, N).new(0)
    encode_into_pointer(value, ary.to_unsafe, size, alphabet)

    ary
  end

  # Encode an integer into a new Array(UInt8).
  @[AlwaysInline]
  def self.encode(value : Int, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet)
  end

  # Encode an integer into a new Array(Char).
  @[AlwaysInline]
  def self.encode(value : Int, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet).map(&.chr)
  end

  # Encode an integer into an existing String, safely. What this does is to allocate a _new_ String
  # of sufficient length to contain both the original string and the encoded value. It copies the
  # original string into the new string, and the encodes the value directly into the string buffer
  # following the original string before returning the new String.
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

  # Encode an integer into an existing String the unsafe way. Crystal strings are immutable, but
  # one can work around that. A String's maximum capacity can not be increased, and the burden
  # here in on the programmer to _ensure_ that the string that is being encoded into has enough
  # capacity for the encoded value.
  #
  # The encoded value will replace the previous value in the string.
  #
  # ```
  # string = (0123456789) * 7
  # encoded = Base58.encode("encode me, please", string)
  # puts encoded # => ""xHSYK7uPSx96i9tu3tVH5Ak"
  # ```
  #
  @[AlwaysInline]
  def self.unsafe_encode(value : Int, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value, into, calculate_size_for_int(value), alphabet)
  end

  # Encode an integer into an existing StringBuffer, safely. What this does is to allocate a _new_ Stri
  @[AlwaysInline]
  def self.encode(value : Int, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value, into.buffer, calculate_size_for_int(value), alphabet)
    into.buffer
  end

  # Encode an Integer into an existing array of UInt8.
  @[AlwaysInline]
  def self.encode(value : Int, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_array(value, into, calculate_size_for_int(value), alphabet)
  end

  # Encode an integer into an existing pointer. Most of the encoding methods end up here.
  @[AlwaysInline]
  def self.encode(value : Int, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value, into, calculate_size_for_int(value), alphabet)
  end

  # Encode an integer into an existing StaticArray(UInt8, _) or Slice(UInt8). The burden is on the user
  # to ensure that there is adequate space in the Slice or StaticArray for the encoded data.
  #
  # Also, be aware that the idea of encoding into an existing StaticArray works from a syntax point of view,
  # but because a StaticArray lives on the stack, this is not what happens. In Crystal, items which are
  # allocated on the stack are passed by copy, which means that when called on a StaticArray, this code
  # will actually return a _new_ StaticArray with the encoded data inserted into it. i.e. the end result
  # is the same as if the `encode` method had been called with a class specification like
  # `into: StaticArray(UInt8, 128)`.
  #
  @[AlwaysInline]
  def self.encode(value : Int, into : StaticArray(UInt8, _) | Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value, into.to_unsafe, calculate_size_for_int(value), alphabet)
    into
  end

  # Encode a String into a new String. This is the default.
  @[AlwaysInline]
  def self.encode(value : String, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, String, alphabet)
  end

  # Encode a String into a new String, with checksumming. This signature accepts an instance of `Base58::Check`,
  # which is used to specify the prefix byte(s), if any, and the checksum algorithm to use.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, String, alphabet)
  end

  # Encode a String into a new StringBuffer. A StringBuffer is a purpose-built container for a mutable string
  # to be used as a data buffer.
  @[AlwaysInline]
  def self.encode(value : String, into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  # Encode a String into a new StringBuffer, with checksumming. A StringBuffer is a purpose-built container for a
  # mutable string to be used as a data buffer.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encode a String into a new raw memory buffer, pointed to by a Pointer(UInt8). This method will allocate
  # a section of memory sufficient to hold the encoded string, and will return a tuple containing the
  # pointer to the raw memory buffer and the size of the buffer.
  @[AlwaysInline]
  def self.encode(value : String, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Pointer, alphabet)
  end

  # Encode a String into a new raw memory buffer, pointed to by a Pointer(UInt8), with checksumming.
  # This method will allocate a section of memory sufficient to hold the encoded string, and will return
  # a tuple containing the pointer to the raw memory buffer and the size of the buffer.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Pointer, alphabet)
  end

  # Encode a String into a new Slice(UInt8). This method will allocate Slice(UInt8) with sufficient space
  # to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Slice(UInt8), alphabet)
  end

  # Encode a String into a new Slice(UInt8), with checksumming. This method will allocate Slice(UInt8) with
  # sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Slice(UInt8), alphabet)
  end

  # Encode a String into a new StaticArray(UInt8, N). This method will allocate a StaticArray(UInt8, N) with
  # sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    encode(value.to_slice, StaticArray(UInt8, N), alphabet)
  end

  # Encode a String into a new StaticArray(UInt8, N), with checksumming. This method will allocate a
  # StaticArray(UInt8, N) with sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StaticArray(T, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall T, N
    encode(value.to_slice, check, StaticArray(UInt8, N), alphabet)
  end

  # Encode a String into a new Array(UInt8), returning it. Each byte of the encoded data will be inserted
  # into an element of the array.
  @[AlwaysInline]
  def self.encode(value : String, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Array(UInt8), alphabet)
  end

  # Encode a String into a new Array(UInt8), with checksumming. This method will allocate an Array(UInt8)
  # with sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Array(UInt8), alphabet)
  end

  # Encode a String into a new Array(Char), returning it. Each byte of the encoded data will be inserted
  # into an element of the array.
  @[AlwaysInline]
  def self.encode(value : String, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, Array(Char), alphabet)
  end

  # Encode a String into a new Array(Char), with checksumming. This method will allocate an Array(Char)
  # with sufficient space to contain the encoded data, returning it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, Array(Char), alphabet)
  end

  # Encode a String into an existing String. Because Strings are immutable, the return value of this method
  # will be a new String containing the contents of the original string with the encoded data concatenated
  # onto the end of it.
  @[AlwaysInline]
  def self.encode(value : String, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  # Encode a String into an existing String, with checksumming. Because Strings are immutable, the return
  # value of this method will be a new String containing the contents of the original string with the
  # encoded data concatenated onto the end of it.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encode a string into an existing String by mutating the original string. The original string much have
  # sufficient capacity to hold the encoded data. This is very fast, but the method is labeled unsafe for
  # a reason. It generally works just fine, so long as the string capacity is adequate, but I can't rule
  # out any possibility of surprises.
  @[AlwaysInline]
  def self.unsafe_encode(value : String, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    unsafe_encode(value.to_slice, into, alphabet)
  end

  # Encode a string into an existing String by mutating the original string, with checksumming. The original
  # string much have sufficient capacity to hold the encoded data. This is very fast, but the method is
  # labeled unsafe for a reason. It generally works just fine, so long as the string capacity is adequate,
  # but I can't rule out any possibility of surprises.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    unsafe_encode(value.to_slice, check, into, alphabet)
  end

  # Encode a string into an existing StringBuffer.
  @[AlwaysInline]
  def self.encode(value : String, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  # Encode a string into an existing StringBuffer, with checksumming.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encode a string into an Array(UInt8) or Array(Char). The new values will be appended to whatever
  # already exists in the array.
  @[AlwaysInline]
  def self.encode(value : String, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  # Encode a string into an Array(UInt8) or Array(Char), with checksumming. The new values will be appended
  # to whatever already exists in the array.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encode a string into an existing memory buffer, pointed to by a Pointer(UInt8). There is assumed to be
  # sufficient space in the buffer to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : String, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  # Encode a string into an existing memory buffer, pointed to by a Pointer(UInt8), with checksumming. There
  # is assumed to be sufficient space in the buffer to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encodes a string into a buffer composed of either a Slice(UInt8) or a StaticArray(UInt8, _). The buffer
  # is assumed to be sufficient space in the buffer to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : String, into : StaticArray(UInt8, _) | Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, into, alphabet)
  end

  # Encodes a string into a buffer composed of either a Slice(UInt8) or a StaticArray(UInt8, _), with
  # checksumming. There is assumed to be sufficient space in the buffer to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : String, check : Base58::Check, into : StaticArray(UInt8, _) | Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.to_slice, check, into, alphabet)
  end

  # Encodes a StringBuffer into any target that a String can be encoded into. If no target is specified,
  # it will default to a String.
  @[AlwaysInline]
  def self.encode(value : StringBuffer, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.buffer, into, alphabet)
  end

  # Encodes a StringBuffer into any target that a String can be encoded into, with checksumming. If no
  # target is specified, it will default to a String.
  @[AlwaysInline]
  def self.encode(value : StringBuffer, check : Base58::Check, into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode(value.buffer, check, into, alphabet)
  end

  # Encodes an Array(UInt8) into any target that a String can be encoded into. If no target is specified,
  # it will default to a String.
  @[AlwaysInline]
  def self.encode(value : Array(UInt8), into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size]? || value.size).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte
    end
    encode(Slice.new(ptr, value.size), into, alphabet)
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

  # Encodes an Array(Char) into any target that a String can be encoded into. If no target is specified,
  # it will default to a String.
  @[AlwaysInline]
  def self.encode(value : Array(Char), into = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    ptr = GC.malloc_atomic(SizeLookup[value.size]? || value.size).as(UInt8*)
    value.each_with_index do |byte, i|
      ptr[i] = byte.ord.to_u8
    end
    encode(Slice.new(ptr, value.size), into, alphabet)
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

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a new String. This is the default for encoding a Slice
  # or for a StaticArray.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_string(value.to_unsafe, value.size, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a new String, with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : String.class = String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_string(value.to_unsafe, value.size, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a new StringBuffer.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer = StringBuffer.new(SizeLookup[value.size]? || value.size * 2)
    encode_into_string(value.to_unsafe, buffer.buffer, value.bytesize, alphabet)
    buffer
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a new StringBuffer, with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StringBuffer.class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    buffer = StringBuffer.new(SizeLookup[value.size + check.prefix.bytesize + 4]? || (value.size + check.prefix.bytesize + 4) * 2)
    encode_into_string(value.to_unsafe, check, buffer.buffer, value.bytesize, check, alphabet)
    buffer
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated memory buffer. The buffer will have sufficient size to hold the encoded
  # data. This method will return a tuple containing the pointer to the data, and its byte size.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Tuple(Pointer(UInt8), Int32)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.bytesize, alphabet)
    {pointer, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated memory buffer, with checksumming. The buffer will have sufficient size to hold the encoded
  # data. This method will return a tuple containing the pointer to the data, and its byte size.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Pointer.class | Pointer(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Tuple(Pointer(UInt8), Int32)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.bytesize, check, alphabet)
    {pointer, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Slice. The Slice will have sufficient size to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Slice(UInt8)
    Slice.new(*encode_to_pointer(value.to_unsafe, value.bytesize, alphabet))
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Slice, with checksumming. The Slice will have sufficient size to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Slice(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin) : Slice(UInt8)
    Slice.new(*encode_to_pointer(value.to_unsafe, value.bytesize, check, alphabet))
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated StaticArray. The StaticArray will have sufficient size to hold the encoded data.
  # The method will return a tuple containing the StaticArray and its byte size.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StaticArray(UInt8, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    ary = StaticArray(UInt8, N).new(0)
    _, final_size = encode_into_pointer(value.to_unsafe, ary.to_unsafe, value.size, alphabet)

    {ary, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated StaticArray, with checksumming. The StaticArray will have sufficient size to hold the encoded data.
  # The method will return a tuple containing the StaticArray and its byte size.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StaticArray(UInt8, N).class, alphabet : Alphabet.class = Alphabet::Bitcoin) forall N
    ary = StaticArray(UInt8, N).new(0)
    _, final_size = encode_into_pointer(value.to_unsafe, check, ary.to_unsafe, value.size, check, alphabet)

    {ary, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Array(UInt8).
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Array(UInt8), with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Array(UInt8).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, check, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Array(Char).
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, alphabet).map(&.chr)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into a newly allocated Array(Char), with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Array(Char).class, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_to_array(value, check, alphabet).map(&.chr)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String. This method actually creates a new String that contains a copy of
  # the contents of the original string, and then concatenates the encoded data to it, and returns the new String.
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

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String, with checksumming. This method actually creates a new String that contains a copy of
  # the contents of the original string, and then concatenates the encoded data to it, and returns the new String.
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

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String. This method defaults to the safe, non-mutating behavior, where
  # the encoded data is concatenated to the original string, and a new String is returned. If you want to mutate the original string, set `mutate: true`.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : String, mutate : Bool = false, alphabet : Alphabet.class = Alphabet::Bitcoin)
    if mutate
      unsafe_encode(value, into, alphabet)
    else
      encode(value, into, alphabet)
    end
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing StringBuffer.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, into.buffer, value.bytesize, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing StringBuffer, with checksumming.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StringBuffer, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, check, into.buffer, value.bytesize, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String. This method is unsafe, and will mutate the original string.
  @[AlwaysInline]
  def self.unsafe_encode(value : Slice(UInt8) | StaticArray(UInt, _), into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, into, value.bytesize, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing String, with checksumming. This method is unsafe, and will mutate the original string.
  @[AlwaysInline]
  def self.unsafe_encode(value : Slice(UInt8) | StaticArray(UInt, _), check : Base58::Check, into : String, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_string(value.to_unsafe, check, into, value.bytesize, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Array(UInt8) or Array(Char). The encoded data is appended to the end of the array,
  # one byte per array element.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_array(value.to_unsafe, into, value.size, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Array(UInt8) or Array(Char), with checksumming. The encoded data is appended to the end of the array,
  # one byte per array element.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Array(UInt8) | Array(Char), alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_array(value.to_unsafe, check, into, value.size, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Pointer(UInt8). The pointer is assumed to reference a section of memory large enough
  # to hold the encoded data. The method returns a tuple containing the pointer and the size of the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) : {Pointer(UInt8), Int32}
    encode_into_pointer(value.to_unsafe, into, value.size, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Pointer(UInt8), with checksumming. The pointer is assumed to reference a section of memory large enough
  # to hold the encoded data. The method returns a tuple containing the pointer and the size of the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Pointer(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) : {Pointer(UInt8), Int32}
    encode_into_pointer(value.to_unsafe, check, into, value.size, alphabet)
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Slice(UInt8). The Slice is assumed to have sufficient space
  # to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) : Slice(UInt8)
    encode_into_pointer(value.to_unsafe, into.to_unsafe, value.size, alphabet)
    into
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing Slice(UInt8), with checksumming. The Slice is assumed to have sufficient space
  # to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : Slice(UInt8), alphabet : Alphabet.class = Alphabet::Bitcoin) : Slice(UInt8)
    encode_into_pointer(value.to_unsafe, check, into.to_unsafe, value.size, alphabet)
    into
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing StaticArray(UInt8, _). The StaticArray is assumed to have sufficient space
  # to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), into : StaticArray(UInt8, _), alphabet : Alphabet.class = Alphabet::Bitcoin)
    _, final_size = encode_into_pointer(value.to_unsafe, into.to_unsafe, value.size, alphabet)
    {into, final_size}
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) into an already existing StaticArray(UInt8, _), with checksumming. The StaticArray is assumed to have sufficient space
  # to hold the encoded data.
  @[AlwaysInline]
  def self.encode(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, into : StaticArray(UInt8, _), alphabet : Alphabet.class = Alphabet::Bitcoin)
    _, final_size = encode_into_pointer(value.to_unsafe, check, into.to_unsafe, value.size, alphabet)
    {into, final_size}
  end

  # ----- The following methods are more specific, providing common functionality that is leveraged by the more general methods above.   -----
  # ----- While they are not marked as private, it is a better practice to use `#encode` unless you have a specific reason to not do so. -----

  # Encodes an Integer to a new Array(UInt8).
  @[AlwaysInline]
  def self.encode_to_array(value : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    size = calculate_size_for_int(value)
    pointer, _ = encode_to_pointer(value, alphabet)
    Array(UInt8).new(size) do |i|
      pointer[i]
    end
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) to a new Array(UInt8).
  @[AlwaysInline]
  def self.encode_to_array(value : Slice(UInt8) | StaticArray(UInt8, _), alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.size, alphabet)
    Array(UInt8).new(final_size) do |i|
      pointer[i]
    end
  end

  # Encodes a Slice(UInt8) or a StaticArray(UInt8, _) to a new Array(UInt8), with checksumming.
  @[AlwaysInline]
  def self.encode_to_array(value : Slice(UInt8) | StaticArray(UInt8, _), check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin)
    pointer, final_size = encode_to_pointer(value.to_unsafe, value.size, check, alphabet)
    Array(UInt8).new(final_size) do |i|
      pointer[i]
    end
  end

  # Encodes an Integer into a newly allocated memory buffer.
  @[AlwaysInline]
  def self.encode_to_pointer(value : Int, alphabet : Alphabet.class = Alphabet::Bitcoin) : {Pointer(UInt8), Int32}
    size = calculate_size_for_int(value)
    ptr = GC.malloc_atomic(size).as(UInt8*)
    encode_into_pointer(value, ptr, size, alphabet)
  end

  # Encodes the contents of a memory buffer, referenced by a Pointer(UInt8), into a newly allocated memory buffer.
  @[AlwaysInline]
  def self.encode_to_pointer(value : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin) : {Pointer(UInt8), Int32}
    index = 0
    buffer_size = SizeLookup[size]? || size * 2
    ptr = GC.malloc_atomic(buffer_size).as(UInt8*)
    encode_into_pointer(value, ptr, size, alphabet)
  end

  # Encodes the contents of a memory buffer, referenced by a Pointer(UInt8), into a newly allocated memory buffer, with checksumming.
  @[AlwaysInline]
  def self.encode_to_pointer(value : Pointer(UInt8), size : Int, check : Base58::Check, alphabet : Alphabet.class = Alphabet::Bitcoin) : {Pointer(UInt8), Int32}
    index = 0
    buffer_size = SizeLookup[size + check.prefix.bytesize + 4]? || (size + check.prefix.bytesize + 4) * 2
    ptr = GC.malloc_atomic(buffer_size).as(UInt8*)
    encode_into_pointer(value, ptr, size, alphabet)
  end

  # Encodes an Integer into a newly allocated String.
  @[AlwaysInline]
  def self.encode_to_string(value : Int, alphabet : Alphabet.class = Alphabet::Bitcoin) : String
    size = calculate_size_for_int(value)
    String.new(size) do |ptr|
      encode_into_pointer(value, ptr, size, alphabet)
      {size, size}
    end
  end

  # Encodes the contents of a memory buffer, referenced by a Pointer(UInt8), into a newly allocated String.
  @[AlwaysInline]
  def self.encode_to_string(value : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin) : String
    buffer_size = SizeLookup[size]? || (size) * 2
    String.new(buffer_size) do |ptr|
      _, final_size = encode_into_pointer(value, ptr, size, alphabet)
      {final_size, final_size}
    end
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

  # ===== These are dangerous and are thus restricted to internal use =====

  # This encodes an integer into an existing memory buffer. All Integer encoding eventually ends up at this method.
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

  # This encodes the contents of a memory buffer referenced by a Pointer(UInt8) into another existing memory buffer. All non-checksum, non-Monero, non-Integer
  # encoding eventually ends up with this method.
  private def self.encode_into_pointer(value : Pointer(UInt8), pointer : Pointer(UInt8), size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    index = primary_encoding(value, pointer, size, 0)
    index = zero_padding(value, pointer, size, index)
    reverse_encoding(pointer, index, alphabet)

    pointer[index] = 0
    {pointer, index}
  end

  # This encodes the contents of a memory buffer referenced by a Pointer(UInt8) into another existing memory buffer, with checksumming. All non-Monero, non-Integer
  # checksummed encoding eventually ends up with this method.
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

  # This encodes the contents of a memory buffer referenced by a Pointer(UInt8) into another existing memory buffer, for Monero. All Monero encoding eventually
  # ends up with this method.
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

  # This method takes an Int, and encodes it into an existing Array(UInt8).
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

  # This method takes a memory buffer referenced by a Pointer(UInt8), and encodes it into an existing Array(UInt8).
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

  # This method takes an Int, and encodes it into an existing Array(Char).
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

  # This method takes a memory buffer referenced by a Pointer(UInt8), and encodes it into an existing Array(Char).
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

  # This method takes an Int, and encodes it into an existing String. This is, by definition, unsafe, as it is mutating the String's internal buffer,
  # and Crystal strings are generally treated as immutable.
  @[AlwaysInline]
  private def self.encode_into_string(value : Int, string : String, size : Int, alphabet : Alphabet.class = Alphabet::Bitcoin)
    encode_into_pointer(value, (string.as(UInt8*) + String::HEADER_SIZE), size, alphabet)
    header = string.as({Int32, Int32, Int32}*)
    header.value = {String::TYPE_ID, size, size}
    string
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
  #
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
      digit = value[byte_pos].to_u16
      inner_idx = 0
      while inner_idx < index
        byte = pointer[inner_idx]
        digit += byte.to_u16 << 8
        pointer[inner_idx] = (digit % 58).to_u8
        digit //= 58
        inner_idx += 1
      end

      while digit > 0
        pointer[index] = (digit % 58).to_u8
        index += 1
        digit //= 58
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
