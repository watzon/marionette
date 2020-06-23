require "json"

module HTTP
  class Cookie
    include JSON::Serializable

    @[JSON::Field(key: "expiry", converter: Time::EpochConverter)]
    @expires : Time?

    @[JSON::Field(key: "httpOnly")]
    @http_only : Bool
  end
end
