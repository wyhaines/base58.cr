require "../alphabet"
require "./bitcoin"

module Base58
  class Alphabet
    # [IPFS](https://github.com/richardschneider/net-ipfs-core#base58) uses Base58. Some sources refer to its
    # implementation as distinct, but it is actually just the Bitcoin implementation.
    class IPFS < Bitcoin
    end
  end
end
