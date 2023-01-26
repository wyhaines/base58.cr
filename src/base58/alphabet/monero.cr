"../alphabet"

module Base58
  class Alphabet
    # Not to be outdone in the Base58 customizations competition, Monero has another unique spin on the base58 alphabet.
    # With Monero, the base alphabet is the same at the Bitcoin alphabet, but when encoding, Monero breaks the input
    # into 8-byte chunks, encoding each chunk separately, and padding to 11 bytes if the result is shorter than 11, except
    # for the last chunk, which will only be padded to the maximum possible size for the given bitcount of that chunk.
    # Decoding reverses this process.
    #
    # Normally, base58 encoding results in some instability in the length of the final encoded values, but the Monero
    # approach eliminates that instability. This, for example, Monero addresses, which are 69 bytes, will always encode
    # to a 95 byte string.
    #
    # `123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz`
    #
    class Monero < Alphabet
      {% begin %}
      {% alphabet = [49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70, 71, 72, 74, 75, 76, 77, 78, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122] %}
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
