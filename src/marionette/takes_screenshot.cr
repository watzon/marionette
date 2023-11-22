module Marionette
  module TakesScreenshot
    abstract def id : String

    abstract def session : Session

    def take_screenshot(scroll = true)
      session.take_screenshot(id, scroll)
    end

    def save_screenshot(path, scroll = true)
      session.save_screenshot(path, id, scroll)
    end
  end
end
