module Marionette
  enum LocationStrategy
    ID
    XPath
    LinkText
    PartialLinkText
    Name
    TagName
    ClassName
    Css

    def to_s
      super.underscore.downcase.gsub('_', " ") + "_selector"
    end
  end
end
