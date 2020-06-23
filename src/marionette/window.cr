module Marionette
  class Window
    getter session : Session

    getter handle : String

    getter type : Type

    def initialize(@session : Session, @handle : String, @type : Type)
    end

    def self.new(session : Session, type : Type)
      session.new_window(type)
    end

    def self.current(session : Session)
      session.current_window
    end

    def close
      @session.close_window(self)
    end

    def rect
      response = execute("GetWindowRect")
      Rect.from_json(response.to_json)
    end

    def rect=(rect : Rect)
      if @session.w3c?
        @session.execute("SetWindowRect", {
          "height" => rect.height,
          "width"  => rect.width,
          "x"  => rect.x,
          "y"  => rect.y
        })
      else
        @session.stop
        raise Error::UnknownMethod.new("`Window#rect=` is only supported on W3C compatible drivers.")
      end
    end

    def switch
      @session.switch_to_window(self)
    end

    def execute(command, params = {} of String => String)
      new_params = {} of String => JSON::Any

      new_params["$windowHandle"] = JSON::Any.new(@handle)
      params.each do |k, v|
        new_params[k.to_s] = JSON.parse(v.to_json)
      end

      @session.execute(command, params)
    end

    enum Type
      Window
      Tab
    end
  end
end
