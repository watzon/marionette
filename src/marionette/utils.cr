module Marionette
  module Utils
    def self.which(cmd)
      exts = ENV["PATHEXT"]? ? ENV["PATHEXT"].split(";") : [""]
      ENV["PATH"].split(':').each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe)
        }
      end
      nil
    end

    def self.timeout(time, &block)
      start = Time.monotonic
      channel = Channel(Bool).new
      spawn do
        until Time.monotonic > (start + time.milliseconds)
        end
        channel.send(false)
      end
      
      spawn do
        block.call
        channel.send(true)
      end
      
      unless channel.receive
        raise Error::TimeoutError.new
      end
    end
  end
end
