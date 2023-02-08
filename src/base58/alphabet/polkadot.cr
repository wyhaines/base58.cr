require "../alphabet"
require "./bitcoin"

module Base58
  class Alphabet
    # Polkadot, for its SS58 address format, uses the same alphabet as Bitcoin.
    class Polkadot < Bitcoin
    end
  end
end
