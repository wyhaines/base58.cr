module Base58
  # SHAEngine1 is a preallocated Digest::SHA256 for Base58Check and CB58 checksum calculation.
  SHAEngine1 = Digest::SHA256.new

  # This is a preallocated buffer for calculating Base58Check / CB58 checksums. This implementation,
  # without any sort of mutex/locking, is NOT threadsafe. TODO would be to make it so.
  SHABuffer    = Bytes.new(32)
  SHABufferPtr = SHABuffer.to_unsafe
end
