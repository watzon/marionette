require "../src/marionette"

include Marionette

session = WebDriver.create_session(:chrome)
session.navigate "http://demo.guru99.com/test/upload/"

print "Please enter a file path: "
file = STDIN.gets

session.wait_for_element("#uploadfile_0") do |element|
  element.upload_file(file.not_nil!)
end

session.perform_actions do
  click("#terms")
  click("#submitbutton")
end

sleep 5.seconds


