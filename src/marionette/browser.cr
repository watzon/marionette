class Marionette
  class Browser
    alias ViewportDims = NamedTuple(width: Int32, height: Int32)

    getter :connection, :process

    def self.create(
      connection : Connection,
      context_ids : Array(String),
      ignore_https_errors : Bool,
      default_viewport : ViewportDims,
      process : Process
    )
      browser = new(connection, context_ids, ignore_https_errors, default_viewport, process)
      browser
    end

    def initialize(
      @connection : Connection,
      context_ids : Array(String),
      @ignore_https_errors : Bool,
      @default_viewport : ViewportDims,
      @process : Process
    )
    end

    def create_incognito_browser_context
      browser_context_id = connection.send("Target.createBrowserContext")
      context = BrowserContext.new(@connection, self, browser_context_id)
      contexts[browser_context_id] = context
      context
    end

    def browser_contexts
      contexts.values.unshift(@default_context)
    end

    def default_browser_context
      @default_context
    end

    private def dispose_context(context_id)
      connection.send("Target.disposeBrowserContext", {"browserContextId" => context_id})
      contexts.delete(context_id)
    end

    def target_created(event)
      target_info = event["targetInfo"]
      context_id = event["browserContextId"]?
      context = (context_id && contexts.has_key?(context_id)) ? contexts[context_id] : default_context

      target = Target.new(target_info, context, connection.create_session(target_info), ignore_https_errors, default_viewport, screenshot_task_queue)
      @targets[target_info["targetId"]] = target
    end

    def target_destroyed(event)
      target = @targets[event["targetId"]]
      target.initialized_callback.call(false)
      targets.delete(event["targetId"])
      target.closed_callback.call

      emit("Events.Browser.TargetDestroyed", target)
      context.emit("Events.Browser.TargetDestroyed", target)
    end

    def target_info_changed(event)
      target = @targets[event["targetId"]]?
      raise "target should exist before target_info_changed" unless target
      previous_url = target.url
      was_initialized = target.initialized?
      target.target_info_changed(event["targetInfo"])

      if was_initialized && previous_url != target.url
        emit("Events.Browser.TargetChanged", target)
        cintext.emit("Events.Browser.TargetChanged", target)
      end
    end

    def ws_endpoint
      connection.url
    end

    def new_page
      default_context.new_page
    end

    def create_page_in_context(context_id)
      response = connection.send("Target.createTarget", {url: "about:blank", browserContextId: context_id})
      target_id = response["targetId"]
      target = @targets[target_id]
      raise "Failed to create target for page" unless target.initialized?
      target.page
    end

    def targets
      @targets.values.select(&.initalized?)
    end

    def target
      targets.find { |target| target.type == "browser" }
    end

    def wait_for_target(timeout = 30000, &block : Target -> Bool)
      started_at = Time.now
      existing_target = @targets.find(&block)
      return existing_target if existing_target
      result = nil

      on(/Events\.Browser\.(TargetCreated|TargetChanged)/) do |target|
        result = target
      end

      until result
        if Time.now > started_at + timeout.milliseconds
          remove_listener(/Events\.Browser\.(TargetCreated|TargetChanged)/)
          raise "Failed to create target for page"
        end
      end
    end

    def pages
      browser_contexts.map(&.pages).flatten
    end

    def version
      version = get_version
      version.product
    end

    def user_agent
      version = get_version
      version.user_agent
    end

    def close
      close_callback.call(nil)
      disconnect
    end

    def disconnect
      connection.dispose
    end

    def connected?
      !connection.closed?
    end

    private def get_version
      connection.send("Browser.getVersion")
    end

    def check(target)
    end

    class Target
    end

    class BrowserContext
      def initialize(a, b, c)
        pp [a, b, c]
      end
    end
  end
end
