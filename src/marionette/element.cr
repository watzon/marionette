module Marionette
  struct Element
    include Logger

    ELEMENT_KEY = "element-6066-11e4-a52e-4f735466cecf"

    # :nodoc:
    SUBMIT_SCRIPT = <<-JS
      var e = arguments[0].ownerDocument.createEvent('Event');
      e.initEvent('submit', true, true);
      if (arguments[0].dispatchEvent(e)) { arguments[0].submit() };
    JS

    # :nodoc:
    SCROLL_TO_SCRIPT = <<-JS
      arguments[0].scrollIntoView({block: "center", inline: "nearest"});
    JS

    # :nodoc:
    LOCATION_SCRIPT = <<-JS
      return arguments[0].getBoundingClientRect();
    JS

    # :nodoc:
    SCROLLED_TO_LOCATION_SCRIPT = <<-JS
      arguments[0].scrollIntoView(true);
      return arguments[0].getBoundingClientRect();
    JS

    getter session : Session

    getter id : String

    @tag_name : String?

    def initialize(@session : Session, @id : String)
    end

    def w3c?
      @session.w3c?
    end

    def tag_name
      @tag_name ||= execute("GetElementTagName").try(&.as_s)
    end

    def text
      property("innerText").try(&.as_s)
    end

    def visible_text
      execute("GetElementText").try(&.as_s)
    end

    def value
      execute("GetElementValue").try(&.as_s)
    end

    def selected?
      execute("IsElementSelected").try(&.as_bool)
    end

    def enabled?
      execute("IsElementEnabled").try(&.as_bool)
    end

    def displayed?(js = false)
      if (js)
        Log.info { "Using script for :isDisplayed" }
        session.execute_atom(:isDisplayed, self)
      else
        execute("IsElementDisplayed").try(&.as_bool)
      end
    end

    def wait_until_displayed(js = false, **wait_options)
      Wait.until(**wait_options) { displayed?(js) }
    end

    def scroll_to
      @session.execute_script(SCROLL_TO_SCRIPT, self)
    end

    def location
      if w3c?
        result = @session.execute_script(LOCATION_SCRIPT, self)
      else
        result = execute("GetElementLocation")
      end

      Location.from_json(result.to_json)
    end

    def location_once_scrolled_to
      if w3c?
        result = @session.execute_script(SCROLLED_TO_LOCATION_SCRIPT, self)
      else
        result = execute("GetElementLocationOnceScrolledIntoView")
      end

      Location.from_json(result.to_json)
    end

    def size
      if w3c?
        response = execute("GetElementRect")
      else
        response = execute("GetElementSize")
      end

      Size.from_json(response.to_json)
    end

    def rect
      if w3c?
        response = execute("GetElementRect")
        Rect.from_json(response.to_json)
      else
        size = self.size
        location = self.location
        Rect.new(x: location.x, y: location.y, width: size.width, height: size.height)
      end
    end

    def x
      location.x
    end

    def y
      location.y
    end

    def width
      size.width
    end

    def height
      size.height
    end

    def property(name)
      execute("GetElementProperty", {"name" => name})
    end

    def attribute(name)
      Log.info { "Using script for :getAttribute of #{name}" }
      session.execute_atom(:getAttribute, self, name)
    end

    def dom_attribute(name)
      execute("GetElementAttribute", {"name" => name})
    end

    def css_property_value(name)
      execute("GetElementValueOfCssProperty", {"name" => name})
    end

    def send_keys(*keys)
      text = keys.map { |k| k.is_a?(Key) ? k.value.chr : k }.join
      execute("SendKeysToElement", {"text" => text})
    end

    def clear
      execute("ClearElement")
    end

    def click(js = false)
      if js
        session.execute_script("arguments[0].click();", self)
      else
        execute("ClickElement")
      end
    end

    def submit
      if w3c?
        form = find_child("./ancestor-or-self::form", :x_path)
        @session.execute_script(SUBMIT_SCRIPT, [form])
      else
        execute("SubmitElement")
      end
    end

    def upload_file(filepath)
      zipfile = File.tempfile(suffix: ".zip") do |file|
        Compress::Zip::Writer.open(file) do |zip|
          zip.add(File.basename(filepath), File.open(filepath))
        end
      end

      bytes = Base64.encode(File.read(zipfile.path))
      value = execute("UploadFile", {"file" => bytes}).as_s
      send_keys(value)
    end

    def find_child(selector, strategy : LocationStrategy = :css)
      @session.find_element_child(self, selector, strategy)
    end

    def find_children(selector, strategy : LocationStrategy = :css)
      @session.find_element_children(self, selector, strategy)
    end

    def take_screenshot(scroll = true)
      @session.take_screenshot(@id, scroll)
    end

    def save_screenshot(path, scroll = true)
      @session.save_screenshot(path, @id, scroll)
    end

    def execute(command, params = {} of String => String)
      params = params.to_h.transform_keys(&.to_s).transform_values(&.to_s)
      params["$elementId"] = @id
      params["$sessionId"] = @session.id

      result = @session.driver.execute(command, params)
      result["value"]
    end

    def to_json(builder : JSON::Builder)
      builder.start_object
      builder.field("ELEMENT", @id)
      builder.field("element-6066-11e4-a52e-4f735466cecf", @id)
      builder.end_object
    end

    def to_s(io)
      io.puts "  - tag_name: #{tag_name}"
      # io.puts "    text: #{text}"
      # io.puts "    value: #{value}"
      # io.puts "    selected: #{selected?}"
      # io.puts "    enabled: #{enabled?}"
      # io.puts "    displayed: #{displayed?}"
      # io.puts "    location: #{location}"
      # io.puts "    size: #{size}"
      # io.puts "    rect: #{rect}"
      # io.puts "    x: #{x}"
      # io.puts "    y: #{y}"
      # io.puts "    width: #{width}"
      # io.puts "    height: #{height}"
    end
  end
end
