require "openssl/digest"

module Base58
  # SHAEngine1 is a preallocated Digest::SHA256 for Base58Check and CB58 checksum calculation.
  Blake2bEngine = OpenSSL::Digest.new("blake2b512")

  # This is a preallocated buffer for calculating SS58 checksums. This implementation,
  # without any sort of mutex/locking, is NOT threadsafe. TODO would be to make it so.
  BlakeBuffer    = Bytes.new(64)
  BlakeBufferPtr = BlakeBuffer.to_unsafe
end
