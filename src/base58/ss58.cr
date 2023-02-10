require "./encoder_check"
require "./decoder_check"
require "openssl/digest"
require "./singletons/blake2bengine"

module Base58
  # Substrate's SS58 encoding can be used generically in the same way that Base58Check and CB58 can be.
  # However, the intention of the encoding is to encode Substrate addresses, specifically, and when used
  # for that purpose, there are some additional specifications which apply to encoding and to decoding.
  # There is a small, fixed set of byte sizes which can be encoded, and there are some strict rules
  # regarding how the prefix is structured, how the checksum is calculated, and how many bytes of the
  # checksum are used. Details can be found in the [Substrate documentation](https://docs.substrate.io/reference/address-formats/).
  #
  # The methods here provide implementations of the Substrate specific style of using SS58 for encoding
  # and decoding Substrate compatible addresses.
  #
  # NOTE: Some of these overloads are implemented expediently, but there are places where extra memory copying
  # is done, and so there is room for improvement with regard to performance and efficiency.
  module SS58
    ChecksumPrefix = "SS58PRE"

    TwoByteChecksumAddresses = {32, 33}
    OneByteChecksumAddresses = {1, 2, 4, 8}

    @[AlwaysInline]
    def self.checksum(check, value : Pointer(UInt8), size) : {Pointer(UInt8), Slice(UInt8)}
      Base58::Blake2bEngine << check.checksum_prefix
      Base58::Blake2bEngine << check.prefix
      Base58::Blake2bEngine << Slice.new(value, size)
      Base58::Blake2bEngine.final(Base58::BlakeBuffer)
      Base58::Blake2bEngine.reset

      {Base58::BlakeBufferPtr, Base58::BlakeBuffer}
    end

    @[AlwaysInline]
    def self.checksum(check, data : Slice(UInt8)) : {Pointer(UInt8), Slice(UInt8)}
      Base58::Blake2bEngine << check.checksum_prefix
      Base58::Blake2bEngine << check.prefix
      Base58::Blake2bEngine << data
      Base58::Blake2bEngine.final(Base58::BlakeBuffer)
      Base58::Blake2bEngine.reset

      {Base58::BlakeBufferPtr, Base58::BlakeBuffer}
    end

    # :nodoc:
    def self.check_args(address, format)
      if format < 0 || format > 16383 || format == 46 || format == 47
        raise ArgumentError.new("Invalid address format: #{format}")
      end

      address_size = address.size
      if TwoByteChecksumAddresses.includes?(address_size)
        checksum_length = 2
      elsif OneByteChecksumAddresses.includes?(address_size)
        checksum_length = 1
      else
        raise ArgumentError.new("Invalid address size: #{address_size}; Substrate addresses can only be 1, 2, 4, 8, 32, or 33 bytes long")
      end

      if format < 64
        format_bytes = Slice[format.to_u8]
      else
        format_bytes = Slice[
          (((format & 0b0000_000011111100) >> 2) | 0b01000000).to_u8,
          ((format >> 8) | ((format & 0b0000000000000011) << 6)).to_u8,
        ]
      end
      {
        type:            Base58::Checksum::SS58,
        prefix:          String.new(format_bytes),
        checksum_length: checksum_length,
        checksum_prefix: ChecksumPrefix,
      }
    end

    def self.encode_address(address, into : String.class = String, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : Array(UInt8).class, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : Array(Char).class, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : Slice(UInt8).class, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : StaticArray(UInt8, N).class, format : Int = 42) forall N
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : StringBuffer.class, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : Pointer(UInt8).class, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : String, mutate : Bool = false, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)), mutate: mutate)
    end

    def self.encode_address(address, into : Array(UInt8), format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : Array(Char), format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : Slice(UInt8), format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : StaticArray(UInt8, N), format : Int = 42) forall N
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : StringBuffer, format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.encode_address(address, into : Pointer(UInt8), format : Int = 42)
      Base58.encode(address, into: into, check: Check.new(**check_args(address, format)))
    end

    def self.decode_address(address, into : String.class = String, format : Int? = nil)
      String.new(decode_address(address, Slice(UInt8), format))
    end

    def self.decode_address(address, into : Array(UInt8).class, format : Int? = nil)
      buffer = decode_address(address, Slice(UInt8), format)
      Array(UInt8).new(buffer.size) { |i| buffer[i] }
    end

    def self.decode_address(address, into : Array(Char).class, format : Int? = nil)
      buffer = decode_address(address, Slice(UInt8), format)
      Array(Char).new(buffer.size) { |i| buffer[i].chr }
    end

    def self.decode_address(address, into : Slice(UInt8).class, format : Int? = nil)
      buffer = Base58.decode(address, into: Slice(UInt8))

      decoded_format, format_length = decode_and_validate_format(buffer, format)

      buffer_size = buffer.size

      checksum_length = checksum_length(buffer_size)

      checksum = buffer[buffer_size - checksum_length, checksum_length]
      data = buffer[format_length, buffer_size - checksum_length - format_length]

      _, checksum_calculated = checksum(
        Check.new(
          type: Base58::Checksum::SS58,
          prefix: String.new(buffer[0, format_length]),
          checksum_length: checksum_length,
          checksum_prefix: ChecksumPrefix,
        ),
        data)

      raise ArgumentError.new("Invalid checksum.") unless checksum == checksum_calculated[0, checksum_length]

      data
    end

    def self.decode_address(address, into : StaticArray(UInt8, N).class, format : Int? = nil) forall N
      buffer = decode_address(address, Slice(UInt8), format)
      StaticArray(UInt8, N).new { |i| buffer[i] }
    end

    def self.decode_address(address, into : StringBuffer.class, format : Int? = nil)
      StringBuffer.new(decode_address(address, Slice(UInt8), format))
    end

    def self.decode_address(address, into : Pointer(UInt8).class, format : Int? = nil)
      buffer = decode_address(address, Slice(UInt8), format)
      {buffer.to_unsafe, buffer.size}
    end

    def self.decode_address(address, into : String, mutate : Bool = false, format : Int? = nil)
      if mutate
        _, final_size = decode_address(address, into: buffer.to_unsafe, format: format)
        header = buffer.as({Int32, Int32, Int32}*)
        header.value = {String::TYPE_ID, final_size, 0}
      else
        into + decode_address(address, Slice(UInt8), format)
      end
    end

    def self.decode_address(address, into : Array(UInt8), format : Int? = nil)
      buffer = decode_address(address, Slice(UInt8), format)
      buffer.each { |byte| into << byte }
    end

    def self.decode_address(address, into : Array(Char), format : Int? = nil)
      buffer = decode_address(address, Slice(UInt8), format)
      buffer.each { |byte| into << byte.chr }
    end

    def self.decode_address(address, into : Slice(UInt8), format : Int? = nil)
      decode_address(address, into.to_unsafe, format)
    end

    def self.decode_address(address, into : StaticArray(UInt8, N), format : Int? = nil) forall N
      decode_address(address, into.to_unsafe, format)
    end

    def self.decode_address(address, into : StringBuffer, format : Int? = nil)
      into << decode_address(address, String, format)
    end

    def self.decode_address(address, into : Pointer(UInt8), format : Int? = nil)
      buffer_size = probable_decoding_size(address.size)
      buffer = GC.malloc_atomic(buffer_size).as(UInt8*)
      checksum_length = checksum_length(buffer_size)
      Base58.decode(address, into: buffer)

      format_length, decoded_format = decode_and_validate_format(buffer, format)

      checksum = Slice.new(buffer + buffer_size - checksum_length, checksum_length)
      data = Slice.new(buffer + format_length, buffer_size - checksum_length - format_length)

      _, checksum_calculated = checksum(
        Check.new(
          type: Base58::Checksum::SS58,
          prefix: String.new(buffer[0, format_length]),
          checksum_length: checksum_length,
          checksum_prefix: ChecksumPrefix,
        ),
        data)

      raise ArgumentError.new("Invalid checksum.") unless checksum == checksum_calculated[0, checksum_length]

      data
    end

    # :nodoc:
    def self.checksum_length(length)
      case length
      when 35, 11, 7, 5, 36, 37
        2
      when 3, 4, 6, 10
        1
      when 8, 12
        3
      when 9, 13
        4
      when 14
        5
      when 15
        6
      when 16
        7
      when 17
        8
      else
        0
      end
    end

    # :nodoc:
    def self.probable_decoded_size(length)
      (1 + length / 1.365658237309761).to_i
    end

    # :nodoc:
    def self.decode_and_validate_format(buffer, format)
      if buffer[0] & 0b01000000 > 0
        format_length = 2
        decoded_format = ((buffer[0] & 0b0011_1111) << 2) | (buffer[1] >> 6) |
                         ((buffer[1] & 0b0011_1111) << 8)
      else
        format_length = 1
        decoded_format = buffer[0]
      end

      raise ArgumentError.new("Format #{decoded_format} is a reserved SS58 format.") if format == 46 || format == 47
      raise ArgumentError.new("The decoded format, #{decoded_format}, is not the expected format, #{format}.") if format && decoded_format != format

      {decoded_format, format_length}
    end
  end
end

Base58::Checksum.register(Base58::Checksum::SS58) do |prefix, value, size|
  Base58::SS58.checksum(prefix, value, size)
end
