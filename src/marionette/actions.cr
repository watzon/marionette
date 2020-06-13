require "json"

module Marionette
  # API for creating and performing action sequences.
  # Each action method adds one or more actions to a queue. When `#perform`
  # is called, the queued actions fire in order.
  class Actions
    alias ActionValue = String | Int32 | Action
    alias Action = Hash(String, ActionValue)

    enum ActionType
      None
      Key
      Pointer
    end

    enum MouseButton
      Left
      Middle
      Right
    end

    getter queue : Array(Action)
    property pointer_params : Hash(String, String)?

    private getter browser : Browser
    private getter action_type : ActionType
    private getter input_id : String

    def initialize(@browser : Browser, @action_type : ActionType, @input_id, @pointer_params = nil)
      @queue = Array(Action).new
    end

    def pause(duration)
      queue.push(Action{"type" => "pause", "duration" => duration})
      self
    end

    def pointer_move(x, y, duration = nil, origin = nil)
      action = Action{
        "type" => "pointerMove",
        "x"    => x,
        "y"    => y,
      }

      if duration
        action = action.merge(Action{"duration" => duration})
      end

      if origin
        if origin.is_a?(Browser::WebElement)
          action = action.merge(Action{"origin" => Action{Browser::WEB_ELEMENT_KEY => origin.id}})
        else
          action["origin"] = origin
        end
      end

      queue.push(action)
      self
    end

    def pointer_up(button = MouseButton::Left)
      pointer_action("pointerUp", button.to_i)
      self
    end

    def pointer_down(button = MouseButton::Left)
      pointer_action("pointerDown", button.to_i)
      self
    end

    def click(element = nil, button = MouseButton::Left)
      if element
        pointer_move(0, 0, origin: element)
      end
      pointer_down(button).pointer_up(button)
    end

    def key_down(value)
      key_action("keyDown", value)
      self
    end

    def key_up(value)
      key_action("keyUp", value)
      self
    end

    def sendKeys(keys)
      keys.each do |key|
        key_down(key)
        key_up(key)
      end
      self
    end

    def perform
      @browser.perform_actions([to_h])
    end

    private def key_action(subtype, value)
      queue.push(Action{"type" => subtype, "value" => value})
    end

    private def pointer_action(subtype, button)
      queue.push(Action{"type" => subtype, "button" => button})
    end

    def to_h
      hash = {
        "type"       => action_type.to_s.downcase,
        "id"         => @input_id,
        "actions"    => queue,
        "parameters" => @pointer_params,
      }

      hash
    end
  end
end
