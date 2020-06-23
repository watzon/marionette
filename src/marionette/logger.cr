module Marionette
  module Logger
    macro included
      {% begin %}
        {% tname = @type.name.stringify.split("::").map(&.underscore).join(".") %}
        Log = ::Log.for({{ tname }})
      {% end %}
    end
  end
end
