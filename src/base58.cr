require "./base58/version"
# require "./base58/extensions/char"
require "./base58/extensions/string"
require "./base58/encoder"
require "./base58/decoder"

module Base58
  # There are two checksum variants that are supported.
  #
  # * [Base58Check](https://en.bitcoin.it/wiki/Base58Check_encoding) is the checksum algorithm used by Bitcoin. It combines an (optional) version/prefix to
  # the front of the data payload with the data payload, and then an SHA256 hash is calculated from the combined prefix + payload. After that calculation,
  # a second SHA256 hash is calculated from the first, and the first 4 bytes of that second hash are appended to the combined prefix + payload. The result
  # is then Base58 encoded.
  #
  # * [CB58](https://support.avax.network/en/articles/4587395-what-is-cb58) is the checksum algorithm used by Avalanche. It combines an (optional) version/prefix to
  # the front of the data payload with the data payload, and then an SHA256 hash is calculated from the combined prefix + payload. After that calculation,
  # the first 4 bytes of the hash are appended to the combined prefix + payload. The result is then Base58 encoded. i.e. it is essentialy Base58Check without
  # the second SHA256 hash.
  #
  enum Checksum
    Base58Check
    CB58
  end

  # Use this structure to specify that some form of checksumming should be used with the encoding or the decoding.
  #
  # ```
  # Base58.encode("some data", check: Base58::Check.new(:Base58Check, "\x31"))
  # ```
  #
  record Check,
    prefix : String = "\x31",
    type : Checksum = :Base58Check

  class ChecksumMismatch < Exception
  end
end
