class Marionette
  record Viewport, width : Int32, height : Int32, device_scale_factor : Int32?,
    is_mobile : Bool? = false, is_landscape : Bool? = false, has_touch : Bool? = false do
    def mobile?
      @is_mobile
    end

    def lansdcape?
      @is_landscape
    end

    def portrait?
      !lansdcape?
    end

    def touch?
      @has_touch
    end
  end
end
