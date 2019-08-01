module Marionette
  record WindowRect, x : Int32, y : Int32, width : Int32, height : Int32 do
    include JSON::Serializable
  end
end