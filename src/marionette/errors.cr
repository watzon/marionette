module Marionette
  class Error < Exception
    CODE_MAP = {
        7 => NoSuchElement,
        8 => NoSuchFrame,
        9 => UnknownCommand,
       10 => StaleElementReference,
       11 => ElementNotVisible,
       12 => InvalidElementState,
       13 => UnknownError,
       15 => ElementIsNotSelectable,
       17 => JavascriptError,
       19 => XpathLookupError,
       21 => Timeout,
       23 => NoSuchWindow,
       24 => InvalidCookieDomain,
       25 => UnableToSetCookie,
       26 => UnexpectedAlertOpen,
       27 => NoAlertOpen,
       28 => ScriptTimeout,
       29 => InvalidElementCoordinates,
       30 => ImeNotAvailable,
       31 => ImeEngineActivationFailed,
       32 => InvalidSelector,
       33 => SessionNotCreated,
       34 => MoveTargetOutOfBounds,
       51 => InvalidXpathSelector,
       52 => InvalidXpathSelectorReturnTyper,
       60 => ElementNotInteractable,
       61 => InvalidArgument,
       62 => NoSuchCookie,
       63 => UnableToCaptureScreen,
       64 => ElementClickIntercepted,
       65 => InsecureCertificate,
       66 => InvalidCoordinates,
       67 => InvalidSessionId,
       68 => UnknownMethod,
       69 => UnsupportedOperationError,
      403 => InvalidDriverError,
      404 => ReachedErrorPage,
      405 => MethodNotAllowed,
      406 => GenericError,
    }

    def self.from_json(json : JSON::Any)
      if int = json.as_i?
        if CODE_MAP.has_key?(int)
          return CODE_MAP[int].new
        end
      elsif str = json.as_s?
        {% begin %}
          case str
          {% for code, error in CODE_MAP %}
          when /{{ error.id.underscore.gsub(/_/, " ").id }}/i
            return {{ error.id }}.new(str)
          {% end %}
          else
            return GenericError.new(str)
          end
        {% end %}
      end

      GenericError.new(json.to_s)
    end

    {% begin %}
      {% for code, error in CODE_MAP %}
        # {{ error.id.underscore.gsub(/_/, " ").id }}
        class {{ error.id }} < Error
        end
      {% end %}
    {% end %}
  end
end
