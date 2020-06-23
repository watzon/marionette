module Marionette
  enum MouseButton
    Left
    Middle
    Right
  end

  enum PointerType
    Mouse
    Touch
    Pen
  end

  abstract class Origin
    include JSON::Serializable

    class ViewPort < Origin
      getter name = "viewport"
    end

    class Pointer < Origin
      getter name = "pointer"
    end

    class ElementSelector < Origin
      getter name = "elementselector"

      property selector : String

      property location_strategy : LocationStrategy

      def initialize(@selector : String, @location_strategy : LocationStrategy)
      end
    end

    class Element < Origin
      getter name = "element"

      property element_id : String

      def initialize(@element_id : String)
      end
    end
  end

  abstract class Action
    def source_type
      case self
      when KeyUp, KeyDown, KeyPause
        SourceType::Key
      when PointerCancel, PointerDown, PointerMove, PointerPause, PointerUp
        SourceType::Pointer
      else
        raise "Unreachable"
      end
    end

    class KeyUp < Action
      getter name = "keyUp"

      property value : String

      def initialize(@value : String)
      end
    end

    class KeyDown < Action
      getter name = "keyDown"

      property value : String

      def initialize(@value : String)
      end
    end

    class PointerPause < Action
      getter name = "pause"

      property duration : Time::Span

      def initialize(@duration : Time::Span = 0.seconds)
      end
    end

    class KeyPause < Action
      getter name = "pause"

      property duration : Time::Span

      def initialize(@duration : Time::Span = 0.seconds)
      end
    end

    class PointerUp < Action
      getter name = "pointerUp"

      property click_duration : Time::Span

      property button : MouseButton

      def initialize(@button : MouseButton, @click_duration : Time::Span)
      end
    end

    class PointerDown < Action
      getter name = "pointerDown"

      property click_duration : Time::Span

      property button : MouseButton

      def initialize(@button : MouseButton, @click_duration : Time::Span)
      end
    end

    class PointerMove < Action
      getter name = "pointerMove"

      property move_duration : Time::Span

      property x : Float64

      property y : Float64

      property origin : Origin

      def initialize(@x : Float64, @y : Float64, @move_duration : Time::Span, @origin : Origin)
      end
    end

    class PointerCancel
      getter name = "pointerCancel"
    end

    enum SourceType
      Key
      Pointer
    end
  end

  class ActionChain
    DEBUG_MOUSE_MOVE_SCRIPT = <<-JS
      var id = "marionetteMouseDebugging";
      var dotID = "marionetteMouseDebuggingDot";
      var descID = "marionetteMouseDebuggingDescription";
      var element = arguments[0];
      var x = arguments[1];
      var y = arguments[2];
      var rect = element.getBoundingClientRect();
      var el, redDot, description;
      if (document.getElementById(id) == null) {
        el = document.createElement("div");
        redDot = document.createElement("div");
        description = document.createElement("div");
        el.appendChild(redDot);
        el.appendChild(description);
        el.id = id;
        redDot.id = dotID;
        description.id = descID;
        el.style.position = "absolute";
        el.style.zIndex = "100000000";
        el.style.display = "flex";
        el.style.pointerEvents = "none";
        redDot.style.borderRadius = "5px";
        redDot.style.border = "2px solid red";
        redDot.style.backgroundColor = "red";
        redDot.style.width = "5px";
        redDot.style.height = "5px";
        redDot.style.display = "inline-block";
        redDot.style.pointerEvents = "none";
        redDot.style.marginRight = "5px";
        description.style.display = "inline-block";
        description.style.border = "1px solid black";
        description.style.backgroundColor = "white";
        description.style.borderRadius = "3px";
        description.style.pointerEvents = "none";
        description.style.paddingLeft = "5px";
        description.style.paddingRight = "5px";
        document.body.appendChild(el);
      } else {
        el = document.getElementById(id);
        redDot = document.getElementById(dotID);
        description = document.getElementById(descID);
      }
      el.style.top = (rect.top + y) + "px";
      el.style.left = (rect.left + x) + "px";
      description.innerHTML = "Moved to (x: " + el.style.left + ", y: " + el.style.top + ")";
      console.log(x);
      console.log(y);
      console.log(element);
    JS

    getter session : Session

    getter w3c_key_actions : Array(Action)

    getter w3c_pointer_actions : Array(Action)

    getter actions : Array(Tuple(String, Action))

    def initialize(@session : Session,
                   @w3c_key_actions = [] of Action,
                   @w3c_pointer_actions = [] of Action,
                   @actions = [] of Tuple(String, Action))
    end

    def w3c_action(action : Action)
      case action.source_type
      in Action::SourceType::Key
        w3c_key_actions << action
        # Add a pause for Pointer types when a Key type has been added
        # so that webdriver ticks align
        w3c_pointer_actions << Action::PointerPause.new
      in Action::SourceType::Pointer
        w3c_pointer_actions << action
        # Add a pause for Key types when a Pointer type has been added
        # so that webdriver ticks align
        w3c_key_actions << Action::KeyPause.new
      end
      self
    end

    def action(command : String, action : Action)
      actions << {command, action}
      self
    end

    def create_key_up(key : Key | Char | String)
      key = key.is_a?(Key) ? key.value.chr : key
      Action::KeyUp.new(key.to_s)
    end

    def create_key_down(key : Key | Char | String)
      key = key.is_a?(Key) ? key.value.chr : key
      Action::KeyDown.new(key)
    end

    def create_mouse_down(button : MouseButton, duration = 0.seconds)
      Action::PointerDown.new(button, duration)
    end

    def create_mouse_up(button : MouseButton, duration = 0.seconds)
      Action::PointerUp.new(button, duration)
    end

    def mouse_button_down(button : MouseButton = :left, duration = 0.seconds)
      action = create_mouse_down(button, duration)
      if @session.w3c?
        w3c_action(action)
      else
        action("MouseDown", action)
      end
    end

    def mouse_button_up(button : MouseButton = :left, duration = 0.seconds)
      action = create_mouse_up(button, duration)
      if @session.w3c?
        w3c_action(action)
      else
        action("MouseUp", action)
      end
    end

    def create_pointer_move(x : Number, y : Number, duration = 0.seconds, origin = Origin::ViewPort.new)
      Action::PointerMove.new(x.to_f, y.to_f, duration, origin)
    end

    def create_pointer_move(x : Number, y : Number, element : Element, duration = 0.seconds)
      origin = Origin::Element.new(element.id)
      Action::PointerMove.new(x.to_f, y.to_f, duration, origin)
    end

    def create_pointer_move(x : Number, y : Number, selector : String, duration = 0.seconds, location_strategy : LocationStrategy = :css_selector)
      origin = Origin::ElementSelector.new(selector.to_s, location_strategy)
      Action::PointerMove.new(x.to_f, y.to_f, duration, origin)
    end

    def create_pointer_move(element : Element, duration = 0.seconds)
      create_pointer_move(-1.0, -1.0, element, duration)
    end

    def create_pointer_move(selector : String, duration = 0.seconds, location_strategy : LocationStrategy = :css_selector)
      Action::PointerMove.new(
        x: -1, y: -1,
        move_duration: duration,
        origin: Origin::ElementSelector.new(
          selector: selector,
          location_strategy: location_strategy))
    end

    def move_mouse(x : Number, y : Number, duration = 0.seconds, origin = Origin::ViewPort.new)
      if @session.w3c?
        w3c_action(create_pointer_move(x, y, duration, origin))
      else
        raise "moveMouse to absolute x, y is only supported in W3C compatible drivers"
      end
    end

    def move_mouse_to(x : Number, y : Number, duration = 0.seconds)
      move_mouse(x, y, duration, Origin::ViewPort.new)
    end

    def move_mouse_to(element : Element, delta_x : Number, delta_y : Number, duration = 0.seconds)
      if @session.w3c?
        w3c_action(create_pointer_move(delta_x, delta_y, element, duration))
      else
        raise "moveMouseTo with duration is not supported for non-W3C drivers"
      end
    end

    def move_mouse_to(element : Element, delta_x : Number, delta_y : Number)
      if @session.w3c?
        move_mouse_to(element, delta_x, delta_y, 0.seconds)
      else
        action({"MoveTo", create_pointer_move(delta_x, delta_y, element)})
      end
    end

    def move_mouse_to(selector : String, delta_x : Number, delta_y : Number, location_strategy : LocationStrategy = :css_selector)
      action = create_pointer_move(delta_x, delta_y, selector, location_strategy: location_strategy)
      if @session.w3c?
        w3c_action(action)
      else
        action("MoveTo", action)
      end
    end

    def move_mouse_to(element : Element, duration = 0.seconds)
      if @session.w3c?
        w3c_action(create_pointer_move(0, 0, element, duration))
      else
        raise "moveMouseTo with duration is not supported for non-W3C drivers"
      end
    end

    def move_mouse_to(selector : String, duration = 0.seconds, location_strategy : LocationStrategy = :css_selector)
      if @session.w3c?
        w3c_action(create_pointer_move(0, 0, selector, duration: duration, location_strategy: location_strategy))
      else
        raise "moveMouseTo with duration is not supported for non-W3C drivers"
      end
    end

    def move_mouse_to(element : Element)
      if @session.w3c?
        move_mouse_to(element, 0.seconds)
      else
        action("MoveTo", create_pointer_move(element, 0.seconds))
      end
    end

    def move_mouse_to(selector : String, location_strategy : LocationStrategy = :css_selector)
      if @session.w3c?
        move_mouse_to(selector, 0.seconds, location_strategy)
      else
        action("MoveTo", create_pointer_move(selector, 0.seconds, location_strategy))
      end
    end

    def move_mouse_by(delta_x : Number, delta_y : Number, duration : Time::Span)
      move_mouse(delta_x, delta_y, duration, Origin::Pointer.new)
    end

    def move_mouse_by(delta_x : Number, delta_y : Number)
      if @session.w3c?
        move_mouse_by(delta_x, delta_y, 0.seconds)
      else
        action("MoveTo", create_pointer_move(delta_x, delta_y, 0.seconds, Origin::Pointer.new))
      end
    end

    def pause(duration = 0.seconds)
      if @session.w3c?
        w3c_action(Action::PointerPause.new(duration: duration))
        w3c_action(Action::KeyPause.new(duration: duration))
        self
      else
        action("Pause", Action::KeyPause.new(duration: duration))
      end
    end

    def click(button : MouseButton = :left)
      mouse_button_down(button)
      mouse_button_up(button)
    end

    def click(element : Element, button : MouseButton = :left)
      move_mouse_to(element).click(button)
    end

    def click(selector : String, button : MouseButton = :left, location_strategy : LocationStrategy = :css_selector)
      move_mouse_to(selector, location_strategy).click(button)
    end

    def right_click
      click(:right)
    end

    def right_click(element : Element)
      click(element, :right)
    end

    def right_click(selector : String, location_strategy : LocationStrategy = :css_selector)
      click(selector, button: :right, location_strategy: location_strategy)
    end

    def click_and_hold(button : MouseButton = :left)
      mouse_button_down(button)
    end

    def click_and_hold(element : Element, button : MouseButton = :left)
      move_mouse_to(element).click_and_hold(button)
    end

    def click_and_hold(selector : String, button : MouseButton = :left, location_strategy : LocationStrategy = :css_selector)
      move_mouse_to(selector, location_strategy).click_and_hold(button)
    end

    def right_click_and_hold
      mouse_button_down(:right)
    end

    def right_click_and_hold(element : Element)
      move_mouse_to(element).right_click_and_hold
    end

    def right_click_and_hold(selector : String, location_strategy : LocationStrategy = :css_selector)
      move_mouse_to(selector, location_strategy).right_click_and_hold
    end

    def double_click(button : MouseButton = :left)
      click(button).click(button)
    end

    def double_click(element : Element, button : MouseButton = :left)
      move_mouse_to(element).double_click(button)
    end

    def double_click(selector : String, button : MouseButton = :left, location_strategy : LocationStrategy = :css_selector)
      move_mouse_to(selector, location_strategy).double_click(button)
    end

    def double_right_click
      click(:right).click(button)
    end

    def double_right_click(element : Element)
      move_mouse_to(element).double_right_click
    end

    def double_right_click(selector : String, location_strategy : LocationStrategy = :css_selector)
      move_mouse_to(selector, location_strategy).double_right_click
    end

    def release(button : MouseButton = :left)
      mouse_button_up(button, 0.seconds)
    end

    def release_right
      mouse_button_up(:right, 0.seconds)
    end

    def release(selector : String, button : MouseButton = :left, location_strategy : LocationStrategy = :css_selector)
      mouse_mouse_to(selector, location_strategy).mouse_button_up(button, 0.seconds)
    end

    def release_right(selector : String, location_strategy : LocationStrategy = :css_selector)
      mouse_mouse_to(selector, location_strategy).mouse_button_up(:right, 0.seconds)
    end

    def drag_and_drop(source : Element, dest : Element)
      click_and_hold(source).release(dest)
    end

    def drag_and_drop(source : String, dest : String, location_strategy : LocationStrategy = :css_selector)
      click_and_hold(source, location_strategy: location_strategy)
        .release(dest, location_strategy: location_strategy)
    end

    def drag_and_drop(source : Element, delta_x : Number, delta_y : Number)
      click_and_hold(source)
        .move_mouse_by(delta_x, delta_y)
        .release
    end

    def drag_and_drop(selector : String, delta_x : Number, delta_y : Number, location_strategy : LocationStrategy = :css_selector)
      click_and_hold(selector, location_strategy: location_strategy)
        .move_mouse_by(delta_x, delta_y)
        .release
    end

    def key_down(key : Key | Char)
      if @session.w3c?
        w3c_action(create_key_down(key))
      else
        action("SendKeysToActiveElement", create_key_down(key))
      end
    end

    def key_up(key : Key | Char)
      if @session.w3c?
        w3c_action(create_key_up(key))
      else
        action("SendKeysToActiveElement", create_key_up(key))
      end
    end

    def key_down(key : Key | Char, element : Element)
      if @session.w3c?
        click(element).w3c_action(create_key_down(key))
      else
        click(element).action("SendKeysToActiveElement", create_key_down(key))
      end
    end

    def key_down(key : Key | Char, selector : String, location_strategy : LocationStrategy = :css_selector)
      if @session.w3c?
        click(selector, location_strategy).w3c_action(create_key_down(key))
      else
        click(selector, location_strategy).action("SendKeysToActiveElement", create_key_down(key))
      end
    end

    def key_up(key : Key | Char, selector : String, location_strategy : LocationStrategy = :css_selector)
      if @session.w3c?
        click(selector, location_strategy).w3c_action(create_key_up(key))
      else
        click(selector, location_strategy).action("SendKeysToActiveElement", create_key_up(key))
      end
    end

    def send_keys(keys : Array(Key | Char | String))
      res = keys.map { |k| k.is_a?(Key) ? k.value.chr : k }.join
      if @session.w3c?
        res.chars.each do |key|
          key_down(key).key_up(key)
        end
      else
        action("SendKeysToActiveElement", create_key_down(res))
      end
    end

    def send_keys(element : Element, keys : Array(Key | Char | String))
      click(element).send_keys(keys)
    end

    def send_keys(selector : String, keys : Array(Key | Char | String), location_strategy : LocationStrategy = :css_selector)
      click(selector, location_strategy: location_strategy).send_keys(keys)
    end

    def send_keys(selector : String, keys : Array(Key | Char | String))
      send_keys(selector, keys, :css_selector)
    end

    def clear_actions
      if @session.w3c?
        @session.clear_actions
      end
      self
    end

    def reset_actions
      @actions.clear
      @w3c_key_actions.clear
      @w3c_pointer_actions.clear
    end

    def perform(debug_mouse_move = false)
      if @session.w3c?
        pointer_actions = [] of Action
        key_actions = [] of Action
        (0 ... @w3c_key_actions.size).each do |i|
          key_action = @w3c_key_actions[i]
          pointer_action = @w3c_pointer_actions[i]

          case pointer_action
          when Action::PointerMove
            origin = pointer_action.origin
            case origin
            when Origin::ElementSelector
              if pointer_actions.size > 0 || key_actions.size > 0
                @session.execute("W3CActions", create_actions(key_actions, pointer_actions, debug_mouse_move: debug_mouse_move))
              end
              key_actions.clear; key_actions << key_action
              pointer_actions.clear; pointer_actions << pointer_action
              next
            end
          end

          pointer_actions << pointer_action
          key_actions << key_action
        end

        if pointer_actions.size > 0 || key_actions.size > 0
          @session.execute("W3CActions", create_actions(key_actions, pointer_actions, debug_mouse_move: debug_mouse_move))
        end
      else
        @actions.each do |command, action|
          case command
          when "Pause"
            case action
            when Action::PointerPause, Action::KeyPause
              sleep(action.duration)
            end
          else
            @session.execute(command, make_action_object(action))
          end
        end
      end
      self
    end

    private def create_actions(key_actions : Array(Action),
                               pointer_actions : Array(Action),
                               pointer_type : PointerType = :mouse,
                               debug_mouse_move = false)
      {
        actions: [
          {
            type: "key",
            id: UUID.random.to_s,
            actions: key_actions.map { |a| make_action_object(a, debug_mouse_move: debug_mouse_move) }
          },
          {
            type: "pointer",
            id: UUID.random.to_s,
            actions: pointer_actions.map { |a| make_action_object(a, debug_mouse_move: debug_mouse_move) }
          }
        ]
      }
    end

    private def make_action_object(action : Action, debug_mouse_move = false)
      is_w3c = @session.w3c?
      case action
      when Action::KeyUp, Action::KeyDown
        if is_w3c
          {type: action.name, value: action.value}
        else
          {value: action.value}
        end
      when Action::PointerPause, Action::KeyPause
        if is_w3c
          {
            type: action.name,
            value: action.duration.total_seconds,
            duration: action.duration.total_seconds
          }
        else
          NamedTuple.new
        end
      when Action::PointerCancel
        if is_w3c
          {type: action.name}
        else
          NamedTuple.new
        end
      when Action::PointerUp, Action::PointerDown
        if is_w3c
          {type: action.name, duration: action.click_duration.total_seconds, button: action.button.value}
        else
          NamedTuple.new
        end
      when Action::PointerMove
        origin = action.origin
        case origin
        when Origin::ViewPort, Origin::Pointer
          if is_w3c
            {
              type:     action.name,
              duration: action.move_duration.total_seconds,
              x:        action.x,
              y:        action.y,
              origin:   origin.name,
            }
          else
            {
              xoffset: action.x,
              yoffset: action.y,
            }
          end
        when Origin::ElementSelector
          selector = origin.selector
          location_strategy = origin.location_strategy
          @session.wait_for_element(selector, location_strategy) do |element|
            x = action.x
            y = action.y

            if debug_mouse_move
              @session.execute_script(DEBUG_MOUSE_MOVE_SCRIPT, [element, x, y])
            end

            if is_w3c
              {
                type:     action.name,
                duration: action.move_duration.total_seconds,
                x:        x,
                y:        y,
                origin:   element,
              }
            else
              if action.x > 0 && action.y > 0
                {
                  element: element.id,
                  xoffset: x,
                  yoffset: y,
                }
              else
                {
                  element: element.id,
                }
              end
            end
          end
        when Origin::Element
          element = Element.new(id: origin.element_id, session: @session)
          x = action.x
          y = action.y

          if debug_mouse_move
            @session.execute_script(DEBUG_MOUSE_MOVE_SCRIPT, [element, x, y])
          end

          if is_w3c
            {
              type:     action.name,
              duration: action.move_duration.total_seconds,
              x:        x,
              y:        y,
              origin:   {
                "element-6066-11e4-a52e-4f735466cecf": origin.element_id,
              },
            }
          else
            if x > 0 && y > 0
              {
                element: origin.element_id,
                xoffset: x,
                yoffset: y,
              }
            else
              {
                element: origin.element_id,
              }
            end
          end
        else
          raise "Unreachable"
        end
      else
        raise "Unreachable"
      end
    end
  end
end
