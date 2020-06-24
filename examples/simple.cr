require "../src/marionette"

include Marionette

session = WebDriver.create_session(:chrome)
session.navigate "https://google.com"

search_bar = session.find_element!("input[title='Search']")
search_bar.send_keys "crystal programming language", Key::Enter

element = session.wait_for_element("#search a")
element.click

sleep 5.seconds

session.stop
