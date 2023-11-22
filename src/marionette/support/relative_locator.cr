module Marionette
  module Support
    class RelativeLocator
      KEYS = %w[above below left right near distance]

      getter filters : Hash(String, String)
      getter root : String

      def initialize(locator : String)
        @filters, @root = locator.partition { |how, _| KEYS.includes?(how) }.map(&.to_h)
      end
    end
  end
end
