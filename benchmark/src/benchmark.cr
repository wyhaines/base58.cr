require "../../src/base58"
require "base62"
require "../vendor/base58"
require "base_x"
require "../../src/base58/extensions/benchmark"

require "colorize"

module Coloraize
  struct Colorize::Object(T)
    forward_missing_to @object
  end
end

module MyBenchmark
  class Base58
    VERSION = "0.1.0"

    BitcoinCharset = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    FFFFFF         = "\xff\xff\xff"
    NineNineNine   = "999"
    Buffer         = StringBuffer.new(256)
    AltBuffer      = StringBuffer.new(256)
    SliceBuffer    = Slice(UInt8).new(256)
    PRNG           = Random.new

    Encoded_16777215 = ::Base58.encode(16777215)
    Encoded_ffffff   = ::Base58.encode("\xff\xff\xff")
    MoneroAddress    = "12c09d10f3c5f580ddd0765063d9246007f45ef025a76c7d117fe4e811fa78f3959c66f7487c1bef43c64ee0ace763116456666a389eea3b693cd7670c3515a0c043794fbf".hexbytes

    def self.run
      Benchmark.ips do |ips|
        ips.separator("Benchmarking Base58 Crystal implementations\n".colorize.green.bold)
        run_encoder_benchmarks(ips)
        run_decoder_benchmarks(ips)
      end
    end

    def self.run_encoder_benchmarks(ips)
      ips.separator("  Encoder Benchmarks".colorize.green.bold)
      run_our_encoder_benchmarks(ips)
      run_russ_encoder_benchmarks(ips)
      run_basex_encoder_benchmarks(ips)
      run_base62_encoder_benchmarks(ips)
    end

    def self.run_our_encoder_benchmarks(ips)
      ips.separator("    Base58 Version #{Base58::VERSION}".colorize(:light_yellow))
      ips.report("Base58::Encoder => Int to String - 16777215") { ::Base58.encode(16777215) }
      ips.report("Base58::Encoder => String to String - #{FFFFFF.inspect}") { ::Base58.encode(NineNineNine) }
      ips.report("Base58::Encoder => String to existing StringBuffer - #{FFFFFF.inspect}") { ::Base58.encode("\xff\xff\xff", into: Buffer) }
      ips.report("Base58::Encoder => String to existing StringBuffer - 999") { ::Base58.encode("999", into: Buffer) }
      ips.report("Base58::Encoder => String to existing Slice(UInt8) - #{FFFFFF.inspect}") { ::Base58.encode("\xff\xff\xff", into: SliceBuffer) }
      ips.report("Base58::Encoder => Random binary data 256 bytes long") { ::Base58.encode(PRNG.random_bytes(256)) }
      ips.report("Base58::Encoder => Int to existing StringBuffer - 16777215") { ::Base58.encode(16777215, into: Buffer) }

      ips.separator "      Encode a Monero address".colorize.light_yellow.dim
      ips.report("Base58::Encode => String to String - #{MoneroAddress.hexstring[0..8]}..#{MoneroAddress.hexstring[-8..-1]}") { ::Base58.encode(MoneroAddress) }
      ips.report("Base58::Encode => String to StringBuffer - #{MoneroAddress.hexstring[0..8]}..#{MoneroAddress.hexstring[-8..-1]}") { ::Base58.encode(MoneroAddress, into: Buffer) }
    end

    def self.run_russ_encoder_benchmarks(ips)
      ips.separator("    Russ/Base58 Version #{RussBase58::VERSION}".colorize(:light_yellow))
      ips.report("Russ/Base58 - encode => Int to String - 16777215") { ::RussBase58.encode(16777215) }
    end

    def self.run_basex_encoder_benchmarks(ips)
      ips.separator("    BaseX::Base58 Version #{BaseX::VERSION}".colorize(:light_yellow))
      ips.report("BaseX::Base58 - encode => Int to String - 16777215") { ::BaseX::Base58.encode(16777215) }
      ips.report("BaseX::Base58 - encode => String to String - #{FFFFFF.inspect}") { ::BaseX::Base58.encode("\xff\xff\xff".to_slice) }
    end

    def self.run_base62_encoder_benchmarks(ips)
      ips.separator("    Base62 Version 0.1.2".colorize(:light_yellow))
      ips.report("Base62 (w/ Bitcoin Charset) - encode => Int to String - 16777215") { ::Base62.encode(16777215, BitcoinCharset) }
      ips.report("Base62 (w/ Bitcoin Charset) - encode => String to String - #{FFFFFF.inspect}") { ::Base62.encode("\xff\xff\xff", BitcoinCharset) }
      ips.report("Base62 (w/ Bitcoin Charset) => Random binary data 256 bytes long") { ::Base62.encode(PRNG.random_bytes(256), BitcoinCharset) }
    end

    def self.run_decoder_benchmarks(ips)
      ips.separator("  Decoder Benchmarks".colorize.green.bold)
      run_our_decoder_benchmarks(ips)
      run_russ_decoder_benchmarks(ips)
      run_basex_decoder_benchmarks(ips)
      run_base62_decoder_benchmarks(ips)
    end

    def self.run_our_decoder_benchmarks(ips)
      ips.separator("    Base58 Version #{Base58::VERSION}".colorize.light_yellow)
      ips.separator("      Decoding Only".colorize.light_yellow.dim)
      ips.report("Base58::Decoder => String to Int - #{Encoded_16777215.inspect}") { ::Base58.decode(Encoded_16777215, into: UInt128) }
      ips.report("Base58::Decoder => String to String - #{Encoded_ffffff.inspect}") { ::Base58.decode(Encoded_ffffff) }
      ips.report("Base58::Decoder => String to existing StringBuffer - #{Encoded_ffffff.inspect}") { ::Base58.decode(Encoded_ffffff, into: Buffer) }
      ips.report("Base58::Decoder => String to existing Slice(UInt8) - #{Encoded_ffffff.inspect}") { ::Base58.decode(Encoded_ffffff, into: SliceBuffer) }

      ips.separator("      Decoding and Encoding".colorize.light_yellow.dim)
      ips.report("Base58::Encoder/Decoder => String to StringBuffer to StringBuffer - #{FFFFFF.inspect}") {
        ::Base58.decode(
          ::Base58.encode(FFFFFF, into: Buffer),
          into: AltBuffer)
      }
    end

    def self.run_russ_decoder_benchmarks(ips)
      ips.separator("    Russ/Base58 Version #{RussBase58::VERSION}".colorize.light_yellow)
      ips.separator("      (only supports decoding from string to an integer)".colorize.light_yellow.dim)
      ips.report("Russ/Base58 - decode => String to Int - #{Encoded_16777215.inspect}") { ::RussBase58.decode(Encoded_16777215) }
    end

    def self.run_basex_decoder_benchmarks(ips)
      ips.separator("    BaseX::Base58 Version #{BaseX::VERSION}".colorize.light_yellow)
      ips.report("BaseX::Base58 - decode => String to Int - #{Encoded_16777215.inspect}") { ::BaseX::Base58.decode_int(Encoded_16777215) }
      ips.report("BaseX::Base58 - decode => String to String - #{Encoded_ffffff.inspect}") { String.new(::BaseX::Base58.decode(Encoded_ffffff)) }
      ips.report("BaseX::Base58 - decode => String to Slice(UInt8) - #{Encoded_ffffff.inspect}") { ::BaseX::Base58.decode(Encoded_ffffff) }
    end

    def self.run_base62_decoder_benchmarks(ips)
      ips.separator("    Base62 Version 0.1.2".colorize(:light_yellow))
      ips.separator("      (only supports decoding from string to a BigInt)".colorize.light_yellow.dim)
      ips.report("Base62 (w/ Bitcoin Charset) - decode => String to BigInt - #{Encoded_ffffff.inspect}") { ::Base62.decode(Encoded_ffffff, BitcoinCharset) }
    end
  end
end

MyBenchmark::Base58.run
