module Base58
  # Use this structure to specify that some form of checksumming should be used with the encoding or the decoding.
  #
  # ```
  # Base58.encode("some data", check: Base58::Check.new(:Base58Check, "\x31"))
  # ```
  #
  record Check,
    prefix : String = "\x31",
    checksum_prefix = "",
    type : Checksum = :Base58Check,
    checksum_length : Int32 = 4
end
