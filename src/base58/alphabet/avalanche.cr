require "../alphabet"
require "./bitcoin"

module Base58
  class Alphabet
    # Avalanche, for its SS58 address format, uses the same alphabet as Bitcoin.
    class Avalanche < Bitcoin
    end
  end
end
