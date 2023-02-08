require "./checksum"
require "./encoder_check"
require "./decoder_check"
require "./singletons/shaengine1"
require "./singletons/shaengine2"

module Base58
  struct Base58Check
    @[AlwaysInline]
    def self.checksum(check, value, size) : {Pointer(UInt8), Slice(UInt8)}
      Base58::SHAEngine1 << check.prefix
      Base58::SHAEngine1 << Slice.new(value, size)
      Base58::SHAEngine2 << Base58::SHAEngine1.final
      Base58::SHAEngine2.final(Base58::SHABuffer)
      Base58::SHAEngine1.reset
      Base58::SHAEngine2.reset

      {Base58::SHABufferPtr, Base58::SHABuffer}
    end
  end
end

Base58::Checksum.register(Base58::Checksum::Base58Check) do |check, value, size|
  Base58::Base58Check.checksum(check, value, size)
end
