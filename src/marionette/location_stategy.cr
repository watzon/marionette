module Marionette
  LOCATION_FINDERS = {
    LocationStrategy::Class => "class name",
    LocationStrategy::ClassName => "class name",
    LocationStrategy::Css => "css selector",
    LocationStrategy::Id => "id",
    LocationStrategy::Link => "link text",
    LocationStrategy::LinkText => "link text",
    LocationStrategy::Name => "name",
    LocationStrategy::PartialLinkText => "partial link text",
    LocationStrategy::Relative => "relative",
    LocationStrategy::TagName => "tag name",
    LocationStrategy::Xpath => "xpath",
  }

  ESCAPE_CSS_REGEXP = /(['"\\#.:;,!?+<>=~*^$|%&@`{}\-\[\]()])/
  UNICODE_CODE_POINT = 30

  enum LocationStrategy
    # Search using a the HTML `class` property of a given element.
    Class

    # :ditto:
    ClassName

    # Search using a standard CSS selector. (i.e. `#some-element li:nth-child(2) > a`)
    Css

    # Search using the HTML `id` property of the given element.
    ID

    # Use the text of a given link to search.
    Link

    # :ditto:
    LinkText

    # Search using the HTML `name` property of the given element.
    Name

    # Use only some of a given link's text to search.
    PartialLinkText

    # Search using a relative location strategy.
    Relative

    # Search using a tag name (i.e. `div` or `span`)
    TagName

    # Search using an XPath expression. [Here](https://devhints.io/xpath) is a helpful XPath cheatsheet.
    Xpath

    # Search using the exact text content of an element.
    Text

    # Search using the partial text content of an element.
    PartialText

    def convert_locator(what)
      LocationStrategy.convert_locator(self, what)
    end

    def self.convert_locator(how : LocationStrategy, what)
      escaped_what = LocationStrategy.escape_css(what)
      case how
      in LocationStrategy::Css
        { "css selector", what }
      in LocationStrategy::Class, LocationStrategy::ClassName
        { "class name", ".#{escaped_what}" }
      in LocationStrategy::ID
        { "css selector",  "##{escaped_what}"}
      in LocationStrategy::Name
        { "css selector",  "*[name='#{escaped_what}']"}
      in LocationStrategy::TagName
        { "css selector",  what }
      in LocationStrategy::Xpath
        { "xpath", what }
      in LocationStrategy::Link, LocationStrategy::LinkText
        { "link text", what }
      in LocationStrategy::PartialLinkText
        { "partial link text", what }
      in LocationStrategy::Relative
        { "relative", what }
      in LocationStrategy::Text
        { "xpath", "//*[normalize-space(text()) = '#{escaped_what}']" }
      in LocationStrategy::PartialText
        { "xpath", "//*[contains (text(), '#{escaped_what}')]" }
      end
    end

    def self.escape_css(string)
      string = string.gsub(ESCAPE_CSS_REGEXP) { |match| "\\#{match}" }
      string = "\\#{UNICODE_CODE_POINT + Int32.new(string[0])} #{string[1..]}" if string[0].try(&.ascii_number?)
      string
    end
  end
end
