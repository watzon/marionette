require "log"

module Marionette
  # NOTE: `::Log.for(self)` would be equivalent to `::Log.for("marionette")` (underscore)
  #       but on NexPloit the sources used are in Pascal.Case
  Log = ::Log.for("Marionette")
end
