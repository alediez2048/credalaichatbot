# frozen_string_literal: true

# Rack::Attack rate limiting configuration
# Two layers: HTTP-level (Rack::Attack) + application-level (Onboarding::RateLimiter)

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# General per-IP throttle: 60 req/min
Rack::Attack.throttle("req/ip", limit: 60, period: 1.minute) do |req|
  req.ip
end

# Stricter throttle for onboarding routes: 30 req/min
Rack::Attack.throttle("onboarding/ip", limit: 30, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/onboarding")
end

# Safelist health check
Rack::Attack.safelist("allow-health-check") do |req|
  req.path == "/up"
end

# Custom throttled response with friendly JSON
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"] || {}
  retry_after = match_data[:period] || 60

  [
    429,
    {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    },
    [{ error: "Too many requests. Please wait a moment and try again.", retry_after: retry_after }.to_json]
  ]
end
