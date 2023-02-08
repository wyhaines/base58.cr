require "./encoder_check"
require "./decoder_check"
require "openssl/digest"
require "./singletons/blake2bengine"

module Base58
  struct SS58
    ChecksumPrefix = "SS58PRE"

    TwoByteChecksumAddresses = {32, 33}
    OneByteChecksumAddresses = {1, 2, 4, 8}

    CkSum1Lengths = {3, 4, 6, 10}
    CkSum3Lengths = {8, 12}
    CkSum4Lengths = {9, 13}

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

    def self.encode_address(address, into : StaticArray(UInt8, _).class, format : Int = 42)
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

    def self.encode_address(address, into : StaticArray(UInt8, _), format : Int = 42)
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
    end

    def self.decode_address(address, into : Array(Char).class, format : Int? = nil)
    end

    def self.decode_address(address, into : Slice(UInt8).class, format : Int? = nil)
      buffer = Base58.decode(address, into: Slice(UInt8))

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

      buffer_size = buffer.size

      if CkSum1Lengths.includes?(buffer_size)
        checksum_length = 1
      elsif {5, 7, 11, 34 + format_length, 35 + format_length}.includes?(buffer_size)
        checksum_length = 2
      elsif CkSum3Lengths.includes?(buffer_size)
        checksum_length = 3
      elsif CkSum4Lengths.includes?(buffer_size)
        checksum_length = 4
      elsif buffer_size == 14
        checksum_length = 5
      elsif buffer_size == 15
        checksum_length = 6
      elsif buffer_size == 16
        checksum_length = 7
      elsif buffer_size == 17
        checksum_length = 8
      else
        raise ArgumentError.new("Invalid address length #{buffer_size}. A valid Substrate address for this format (#{decoded_format}) will have a length in {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, #{34 + format_length}, #{35 + format_length}}.")
      end

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

    def self.decode_address(address, into : StaticArray(UInt8, _).class, format : Int? = nil)
    end

    def self.decode_address(address, into : StringBuffer.class, format : Int? = nil)
    end

    def self.decode_address(address, into : Pointer(UInt8).class, format : Int? = nil)
    end

    def self.decode_address(address, into : String, mutate : Bool = false, format : Int? = nil)
    end

    def self.decode_address(address, into : Array(UInt8), format : Int? = nil)
    end

    def self.decode_address(address, into : Array(Char), format : Int? = nil)
    end

    def self.decode_address(address, into : Slice(UInt8), format : Int? = nil)
    end

    def self.decode_address(address, into : StaticArray(UInt8, _), format : Int? = nil)
    end

    def self.decode_address(address, into : StringBuffer, format : Int? = nil)
    end

    def self.decode_address(address, into : Pointer(UInt8), format : Int? = nil)
    end

    # :nodoc:
    def self.checksum_length(length)
      case length
      when 35, 11, 7, 5
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
  end
end

Base58::Checksum.register(Base58::Checksum::SS58) do |prefix, value, size|
  Base58::SS58.checksum(prefix, value, size)
end
