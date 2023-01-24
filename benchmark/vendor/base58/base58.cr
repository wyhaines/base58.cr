# This is a copy of https://github.com/russ/base58 with the module changed so that it can be benchmarked
# alongside the Base58 implementation in this shard.

require "big"

module RussBase58
  VERSION = "0.1.2"
  extend self

  class DecodingError < Exception
  end

  ALPHABET = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"
  BASE     = ALPHABET.size

  def encode(int_val : Number) : String
    base58_val = ""
    while int_val >= BASE
      mod = int_val % BASE
      base58_val = ALPHABET[mod.to_big_i, 1] + base58_val
      int_val = (int_val - mod).divmod(BASE).first
    end
    ALPHABET[int_val.to_big_i, 1] + base58_val
  end

  def decode(base58_val : String) : Number
    int_val = BigInt.new
    base58_val.reverse.split(//).each_with_index do |char, index|
      char_index = ALPHABET.index(char)
      raise DecodingError.new("Value passed not a valid Base58 String. (#{base58_val})") if char_index.nil?
      int_val += (char_index.to_big_i) * (BASE.to_big_i ** (index.to_big_i))
    end
    int_val
  end
end
