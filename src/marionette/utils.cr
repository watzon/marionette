class Marionette
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

  end
end
