module Base58
  # There are three checksum variants that are supported.
  #
  # - [Base58Check](https://en.bitcoin.it/wiki/Base58Check_encoding) is the checksum algorithm used by Bitcoin. It combines an (optional) version/prefix to
  # the front of the data payload with the data payload, and then an SHA256 hash is calculated from the combined prefix + payload. After that calculation,
  # a second SHA256 hash is calculated from the first, and the first 4 bytes of that second hash are appended to the combined prefix + payload. The result
  # is then Base58 encoded.
  #
  # - [CB58](https://support.avax.network/en/articles/4587395-what-is-cb58) is the checksum algorithm used by Avalanche. It combines an (optional) version/prefix to
  # the front of the data payload with the data payload, and then an SHA256 hash is calculated from the combined prefix + payload. After that calculation,
  # the first 4 bytes of the hash are appended to the combined prefix + payload. The result is then Base58 encoded. i.e. it is essentialy Base58Check without
  # the second SHA256 hash.
  #
  # - [SS58](https://docs.substrate.io/reference/address-formats/) is the address format and checksum algorithm used by Substrate, the SDK for building Polkadot based
  # blockchains. It combines an (optional) prefix/format code prepended to the data/address, with a variable length checksum appended to the end of the data/address.
  # It uses the Blake2b hash function to calculate the checksum. The address specification for Substrate has a highly constrained definition regarding what
  # a valid input and output looks like. When encoding Substrate addresses, those conventions must be followed. See the `Base58::SS58` documentation for more
  # details about this, as well as methods specifically for encoding and decoding Substrate addresses. The algorithm can be used for any data, however, just
  # as with the other two checksum variants.
  #
  enum Checksum
    Base58Check
    CB58
    SS58

    @@calculators = Array((Base58::Check, Pointer(UInt8), Int32 -> {Pointer(UInt8), Slice(UInt8)})?).new(4) { nil }

    def self.calculate(check : Check, value, size)
      if calculator_proc = @@calculators[check.type.to_i]?
        calculator_proc.call(check, value, size)
      else
        raise "Unknown checksum type: #{check.type}"
      end
    end

    def self.register(type : Checksum, &block : Base58::Check, Pointer(UInt8), Int32 -> {Pointer(UInt8), Slice(UInt8)})
      @@calculators[type.to_i] = block
    end
  end
end

require "./check"
require "./checksum_mismatch"
