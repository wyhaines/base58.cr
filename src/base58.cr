require "./base58/version"
require "./base58/extensions/char"
require "./base58/extensions/string"
require "./base58/extensions/slice"
require "./base58/encoder"
require "./base58/decoder"

module Base58
  # There are two checksum variants that are supported.
  #
  # * [Base58Check](https://en.bitcoin.it/wiki/Base58Check_encoding) is the checksum algorithm used by Bitcoin. It combines an (optional) version/prefix to
  # the front of the data payload, the first 4 characters of the SHA256 hash of the SHA256 has of the
  # checksum + data combination before Base58 encoding.
  #
  # * [CB58](https://support.avax.network/en/articles/4587395-what-is-cb58) 
  #
  enum Checksum
    Base58Check
    CB58
  end

  # Use this structure to specify that some form of checksumming should be used with the encoding or the decoding.
  #
  # ```crystal
  # Base58.encode("some data", check: Base58::Check.new(:Base58Check, "\x31"))
  # ```
  #
  record Check,
    prefix : String = "\x31",
    type : Checksum = :Base58Check

    
  class ChecksumMismatch < Exception
  end
end