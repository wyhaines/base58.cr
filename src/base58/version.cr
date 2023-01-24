# TODO: Write documentation for `Base58`
module Base58
  {% begin %}
  VERSION = {{ read_file("#{__DIR__}/../../VERSION").chomp }}
  {% end %}
end
