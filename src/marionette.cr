require "./core_mods/*"
require "./marionette/logger"
require "./marionette/error"
require "./marionette/*"

# TODO: Write documentation for `Marionette`
class Marionette

  # The launcher instance
  getter launcher : Marionette::Launcher

  # The root directory for this project
  getter project_root : String

  def initialize(project_root = nil, preferred_revision = nil)
    @project_root = project_root || FileUtils.pwd
    @launcher = Launcher.new(project_root.to_s, preferred_revision)
  end

  # See `Launcher#launch`
  def launch(**options)
    @launcher.launch(**options)
  end

  # See `Launcher#connect`
  def connect(**options)
    @launcher.connect(**options)
  end

  # Returns the path to the chrome executable being used
  def executable_path
    @launcher.executable_path
  end

  # Returns the launcher args
  def launcher_args
    @launcher.chrome_args
  end

  # See `Downloader.new`
  def create_downloader(**options)
    Downloader.new(**options)
  end
end
