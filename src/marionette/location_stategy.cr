module Marionette
  enum LocationStrategy
    # Search using the HTML `id` property of the given element.
    ID

    # Search using an XPath expression. [Here](https://devhints.io/xpath) is a helpful XPath cheatsheet.
    XPath

    # Use the text of a given link to search.
    LinkText

    # Use only some of a given link's text to search.
    PartialLinkText

    # Search using the HTML `name` property of the given element.
    Name

    # Search using a tag name (i.e. `div` or `span`)
    TagName

    # Search using a the HTML `class` property of a given element.
    ClassName

    # Search using a standard CSS selector. (i.e. `#some-element li:nth-child(2) > a`)
    Css

    def to_s
      super.underscore.downcase.gsub('_', " ") + " selector"
    end
  end
end
