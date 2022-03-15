require "spec"
require "../src/marionette"

Log.setup do |c|
  backend = Log::IOBackend.new
  level = ENV["LOG_LEVEL"]?.try { |e| Log::Severity.parse(e) } || Log::Severity::Debug
  c.bind("*", level, backend)
end
