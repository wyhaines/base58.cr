"../alphabet"

module Base58
  class Alphabet
    class Ripple < Alphabet
      {% begin %}
      {% alphabet = [114, 112, 115, 104, 110, 97, 102, 51, 57, 119, 66, 85, 68, 78, 69, 71, 72, 74, 75, 76, 77, 52, 80, 81, 82, 83, 84, 55, 86, 87, 88, 89, 90, 50, 98, 99, 100, 101, 67, 103, 54, 53, 106, 107, 109, 56, 111, 70, 113, 105, 49, 116, 117, 118, 65, 120, 121, 122] %}
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
