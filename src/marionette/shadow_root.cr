require "./search_context"

module Marionette
  struct ShadowRoot
    include Logger
    include SearchContext

    ROOT_KEY = "shadow-6066-11e4-a52e-4f735466cecf"

    getter session : Session

    getter id : String

    def initialize(@session : Session, @id : String)
    end

    def to_json(builder : JSON::Builder)
      builder.start_object
      builder.field(ROOT_KEY, @id)
      builder.end_object
    end
  end
end
