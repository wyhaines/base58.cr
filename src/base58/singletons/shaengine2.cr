module Base58
  # SHAEngine2 is a preallocated Digest::SHA256 for Base58Check checksum calculation.
  SHAEngine2 = Digest::SHA256.new
end
