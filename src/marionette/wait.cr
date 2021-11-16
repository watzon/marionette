module Marionette
  class Wait
    DEFAULT_TIMEOUT = 5000.0
    DEFAULT_INTERVAL = 200.0

    property timeout : Float64
    property interval : Float64
    property message : String?
    property ignored : Array(Exception.class)

    def initialize(*,
        timeout : Time::Span | Float64 = DEFAULT_TIMEOUT,
        interval : Time::Span | Float64 = DEFAULT_INTERVAL,
        @message : String? = nil,
        @ignored : Array(Exception.class) = [] of Exception.class
      )
      @ignored << Error::NoSuchElement if @ignored.empty?
      @timeout = timeout.is_a?(Time::Span) ? timeout.total_milliseconds : timeout
      @interval = interval.is_a?(Time::Span) ? interval.total_milliseconds : interval
    end

    def until(&block : -> U) forall U
      end_time = Time.monotonic + @timeout.milliseconds
      last_error : Exception? = nil

      until Time.monotonic > end_time
        begin
          result = yield
          return result if result
        rescue ex
          if @ignored.includes?(ex.class)
            last_error = ex
          else
            raise ex
          end
        end

        sleep @interval.milliseconds
      end

      msg = message ? message.to_s : "timed out after #{@timeout} seconds"
      msg += " (#{last_error.message})" if last_error

      raise Error::Timeout.new(msg)
    end

    def self.until(**options, &block : -> U) forall U
      new(**options).until(&block)
    end
  end
end
