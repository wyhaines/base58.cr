module Colorize
  struct Colorize::Object(T)
    forward_missing_to @object

    def mode(mode : Symbol) : self
      {% begin %}
        case mode
        {% for name in MODES %}
        when :{{name.id}}
          mode(Mode::{{name.capitalize.id}})
        {% end %}
        end
      {% end %}
      return self
    end
  end
end
