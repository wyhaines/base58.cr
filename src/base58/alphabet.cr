module Base58
  # This is the base class for Base58 Alphabet implementations. It is not intended to be used directly.
  class Alphabet
    macro inherited
      # Query the base58 alphabet for the digit/character that represents the given value.
      @[AlwaysInline]
      def self.[](val)
        BaseToUInt[val]
      end

      # Query the base58 alphabet for the digit/character that represents the given value. Returns nil if the value is not in the alphabet.
      @[AlwaysInline]
      def self.[]?(val)
        BaseToUInt[val]?
      end

      # Query the base58 alphabet for the value that the given digit/character represents.
      @[AlwaysInline]
      def self.inverse(val)
        UIntToBase[val]
      end

      # Query the base58 alphabet for the value that the given digit/character represents. Returns nil if the digit/character is not in the alphabet.
      @[AlwaysInline]
      def self.inverse?(val)
        byte = UIntToBase[val]?
        byte && byte != 0 ? byte : nil
      end
    end
  end
end

require "./alphabet/*"
