module Marionette
  module SearchContext
    abstract def session : Session

    def find_element(selector, strategy : LocationStrategy = :css)
      session.find_element_child(self, selector, strategy)
    end

    def find_elements(selector, strategy : LocationStrategy = :css)
      session.find_element_children(self, selector, strategy)
    end
  end
end
