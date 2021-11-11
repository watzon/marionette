require "./spec_helper"

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
  end
end
