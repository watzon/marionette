module Marionette
  enum PageLoadStrategy
    None
    Normal
    Eager

    def to_s(io)
      io << super.downcase
    end
  end

  enum ElementScrollBehavior
    Top
    Bottom

    def to_s(io)
      io << super.downcase
    end
  end

  record Size, height : Float64, width : Float64 do
    include JSON::Serializable
  end

  record Rect, height : Float64, width : Float64, x : Float64, y : Float64 do
    include JSON::Serializable
  end

  record Location, x : Float64, y : Float64 do
    include JSON::Serializable
  end

  struct LogItem
    include JSON::Serializable

    getter level : String

    @[JSON::Field(converter: Time::EpochMillisConverter)]
    getter timestamp : Time

    @[JSON::Field(converter: Marionette::LogItem::MessageConverter)]
    getter message : JSON::Any

    # :nodoc:
    module MessageConverter
      def self.from_json(pull : JSON::PullParser)
        message = JSON.parse(pull.read_string)
        message["message"]
      end

      def self.to_json(value, builder : JSON::Builder)
        value.to_json(builder)
      end
    end
  end
end
