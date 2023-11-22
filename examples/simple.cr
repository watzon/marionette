require "../src/marionette"

include Marionette

session = WebDriver.create_session(:chrome)
session.navigate "https://google.com"

search_bar = session.find_element!("textarea")
search_bar.send_keys "crystal programming language", Key::Enter

# Use xpath to find the first result
session.wait_for_element("//div[@id='search']//a", :xpath) do |element|
  element.click
end

session.wait_for_element("#Crystal") do |element|
  pp session.shadow_root(element)
  sleep 5
end

session.stop
