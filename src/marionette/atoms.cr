module Marionette
  module Atoms
    extend self

    def read_atom(function)
      File.read(File.expand_path("./atoms/#{function.to_s}.js", __DIR__))
    end

    def execute_atom(function_name, *arguments)
      script = "return (#{ read_atom(function_name) }).apply(null, arguments)"
      execute_script(script, *arguments)
    end
  end
end
