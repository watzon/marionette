module Marionette
  record ElementRect, x : Float64, y : Float64, width : Float64, height : Float64 do
    include JSON::Serializable
  end
end
