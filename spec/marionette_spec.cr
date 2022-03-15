require "http"

require "./spec_helper"

module Marionette
  describe Marionette do
    # TODO: Write tests

    it "Initialize" do
      marionette = Marionette.launch(
        # address: @driver_host,
        # port: @driver_port,
        headless: false,
        timeout: 180.seconds,
        accept_insecure_certs: true,
        default_viewport: {
          width:  1920,
          height: 1080,
        },
        executable: false,
      )
      marionette.navigate("about:blank")
      marionette.reduce_memory_usage
      marionette.execute_script(
        "return document.documentElement.outerHTML;"
      ).to_s.should contain("Memory minimization completed")
      marionette.close_session
    end

    it "Clears browser history" do
      webpage = <<-HTML
      <html>
        <head>
          <script defer>
            function probe_local_storage() {
            const d = document.getElementById("message");
            const token = localStorage.getItem("token");
              if (token) {
                console.log("Authorized");
                d.innerHTML = "<p>Authorized</p>";
              } else {
                console.log("Token placed");
                localStorage.setItem("token", "0xDEADBEEF");
                d.innerHTML = "<p>Token placed</p>";
              }
            }
          </script>
        </head>
        <body onload="probe_local_storage();">
          <div id="message"></div>
        </body>
      </html>
      HTML

      server = ::HTTP::Server.new do |context|
        context.response.content_type = "text/html"
        context.response.print(webpage)
      end

      addr = server.bind_unused_port
      Log.debug { "Server listening at #{addr}" }

      spawn do
        Log.debug { "Starting server" }
        server.listen
      end
      Fiber.yield

      marionette = Marionette.launch(
        # address: @driver_host,
        # port: @driver_port,
        headless: false,
        timeout: 180.seconds,
        accept_insecure_certs: true,
        default_viewport: {
          width:  1920,
          height: 1080,
        },
        executable: false,
      )
      marionette.clear_history

      # First run, token is placed in local storage
      marionette.navigate("http://localhost:#{addr.port}")
      marionette.execute_script(
        "return document.documentElement.outerHTML;"
      ).to_s.should contain(%[<div id="message"><p>Token placed</p></div>])

      # Second run, token is in place
      marionette.navigate("http://localhost:#{addr.port}")
      marionette.execute_script(
        "return document.documentElement.outerHTML;"
      ).to_s.should contain(%[<div id="message"><p>Authorized</p></div>])

      # Clearing history and re-checking
      marionette.clear_history
      marionette.navigate("http://localhost:#{addr.port}")
      marionette.execute_script(
        "return document.documentElement.outerHTML;"
      ).to_s.should contain(%[<div id="message"><p>Token placed</p></div>])

      marionette.close_session
    end
  end
end
