require "strange"
require "strange/formatter/color_formatter"

class Marionette
  module Logger
    class_property logger = Strange.new(Strange::DEBUG, transports: [
      Strange::ConsoleTransport.new(formatter: Formatter.new).as(Strange::Transport),
    ])

    delegate :emerg, :alert, :crit, :error, :warning, :notice, :info, :debug, to: @@logger

    {% for level in [:emerg, :alert, :crit, :error, :warning, :notice, :info, :debug] %}
      def self.{{ level.id }}(message)
        @@logger.{{ level.id }}(message)
      end
    {% end %}

    class Formatter < Strange::ColorFormatter
      def format(text : String, level : Strange::Level)
        lvl = "[" + ("%-7.7s" % level.to_s) + "]"
        color_message("#{lvl} - #{text}", level)
      end
    end
  end
end
