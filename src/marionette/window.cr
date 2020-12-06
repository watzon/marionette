module Marionette
  class Window
    include Logger

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

    def switch
      @session.switch_to_window(self)
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

    def set_rect(x, y, width, height)
      rect = Rect.new(x: x.to_f, y: y.to_f, width: width.to_f, height: height.to_f)
      self.rect = rect
    end

    def size
      if @session.w3c?
        if @handle != @session.current_window.handle
          Log.warn { "Only current window is supported for W3C Compatible browsers" }
        end
        rect = self.rect
        Size.new(width: rect.width, height: rect.height)
      else
        response = execute("GetWindowSize")
        Size.from_json(response.to_json)
      end
    end

    def size=(size : Size)
      if @session.w3c?
        if @handle != @session.current_window.handle
          Log.warn { "Only current window is supported for W3C Compatible browsers" }
        end
        rect = self.rect
        rect.width = size.width
        rect.height = size.height
        self.rect = rect
      else
        execute("SetWindowSize", {"width" => size.width, "height" => size.height})
      end
    end

    def resize_to(width, height)
      size = Size.new(width: width.to_f, height: height.to_f)
      self.size = size
    end

    def position
      if @session.w3c?
        if @handle != @session.current_window.handle
          Log.warn { "Only current window is supported for W3C Compatible browsers" }
        end
        rect = self.rect
        Location.new(x: rect.x, y: rect.y)
      else
        response = execute("GetWindowPosition")
        Location.from_json(response.to_json)
      end
    end

    def position=(position : Location)
      if @session.w3c?
        if @handle != @session.current_window.handle
          Log.warn { "Only current window is supported for W3C Compatible browsers" }
        end
        rect = self.rect
        rect.x = position.x
        rect.y = position.y
        self.rect = rect
      else
        execute("SetWindowSize", {"x" => position.x, "y" => position.y})
      end
    end

    def move_to(x, y)
      position = Location.new(x: x.to_f, y: y.to_f)
      self.position = position
    end

    def maximize
      if @session.w3c?
        execute("W3CMaximizeWindow")
      else
        execute("MaximizeWindow")
      end
    end

    def minimize
      execute("MinimizeWindow")
    end

    def fullscreen
      execute("FullScreenWindow")
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
