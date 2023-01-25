module Base58
  # This is the base class for Base58 Alphabet implementations. It is not intended to be used directly.
  class Alphabet
    macro inherited
      @[AlwaysInline]
      def self.[](val)
        BaseToUInt[val]
      end

      @[AlwaysInline]
      def self.[]?(val)
        BaseToUInt[val]?
      end

      @[AlwaysInline]
      def self.inverse(val)
        UIntToBase[val]
      end

      @[AlwaysInline]
      def self.inverse?(val)
        byte = UIntToBase[val]?
        byte && byte != 0 ? byte : nil
      end
    end
  end
end

require "./alphabet/*"
