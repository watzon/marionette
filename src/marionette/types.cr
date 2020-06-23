module Marionette
  record Size, height : Float64, width : Float64 do
    include JSON::Serializable
  end

  record Rect, height : Float64, width : Float64, x : Float64, y : Float64 do
    include JSON::Serializable
  end

  record Location, x : Float64, y : Float64 do
    include JSON::Serializable
  end
end
