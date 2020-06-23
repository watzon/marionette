module Marionette
  enum LocationStrategy
    IDSelector
    XPathSelector
    LinkTextSelector
    PartialLinkTextSelector
    NameSelector
    TagNameSelector
    ClassNameSelector
    CssSelector

    def to_s
      super.underscore.downcase.gsub('_', " ")
    end
  end
end
