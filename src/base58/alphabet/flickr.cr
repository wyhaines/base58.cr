require "../alphabet"

module Base58
  class Alphabet
    # The modern usage of Base58 can be traced back to 2009. It appears that [Flickr](https://www.flickr.com/groups/api/discuss/72157616713786392/)
    # was using it before [Bitcoin](https://github.com/bitcoin/bitcoin/blob/v0.1.5/base58.h#L7), but Bitcoin gets all the glory, so most general purpose
    # Base58 implementations, including this one, use Bitcoin's alphabet as the default. The Flickr alphabet differs from the Bitcoin alphabet in that
    # the Flickr alphabet has the lowercase letters preeceding the uppercase letters.
    #
    # `123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ`
    #
    class Flickr < Alphabet
      {% begin %}
      {% alphabet = [49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 65, 66, 67, 68, 69, 70, 71, 72, 74, 75, 76, 77, 78, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90] %}
      BaseToUInt = UInt8.static_array({% for i in alphabet %}{{ i }}, {% end %})
      UIntToBase = UInt8.static_array(
      {% idx = 0 %}
      {% working_set = [] of UInt8 %}
      {% for i in 0..255 %}
      {% working_set << 0_u8 %}
      {% end %}
      {% for uint in alphabet %}
      {% working_set[uint] = idx %}
      {% idx += 1 %}
      {% end %}
      {% for base in working_set %}
      {{base}},
      {% end %}
      )
      {% end %}
    end
  end
end
