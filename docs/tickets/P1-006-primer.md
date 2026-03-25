# P1-006 — Rate limiting & abuse prevention

**Priority:** P1
**Estimate:** 2 hours
**Phase:** 1 — AI Chatbot Core (MVP GATE)
**Status:** Not started

---

## Goal

Prevent abuse of the chat endpoint by enforcing per-session and per-IP rate limits. Users who send too many messages in a short window receive a friendly, non-technical error message with a retry-after hint. The system protects LLM API costs and keeps the service available for all users.

---

## Prerequisites (BLOCKERS)

| Ticket | Why it blocks P1-006 |
|--------|----------------------|
| **P1-001** | Chat UI + Action Cable channel must exist to enforce limits on |
| **P1-004** | Error handling patterns (structured error broadcasts, retry UI) must be in place |

---

## Deliverables Checklist

- [ ] `rack-attack` gem added to Gemfile
- [ ] `config/initializers/rack_attack.rb` — Rack::Attack configuration with throttle rules
- [ ] Per-IP throttle: max 30 requests/minute to `/onboarding` routes
- [ ] Per-IP throttle: max 60 requests/minute globally (safeguard)
- [ ] Application-level per-session rate limit in `OnboardingChatChannel#send_message` (max 10 messages/minute per session)
- [ ] Friendly error response when Rack::Attack throttles a request (429 with JSON body)
- [ ] Friendly error broadcast when channel-level limit is hit (uses existing error broadcast pattern from P1-004)
- [ ] Safelist for health check endpoint (`/up`)
- [ ] Rate limit headers in throttled responses (`Retry-After`)
- [ ] Unit tests for channel-level rate limiting logic
- [ ] Integration test for Rack::Attack throttle rules
- [ ] Test that friendly error message is returned (not a raw 429)

---

## Acceptance Criteria

| # | Criterion | How to verify |
|---|-----------|----------------|
| 1 | Sending >10 messages/minute in a session triggers a rate limit error | Rapid-fire messages in chat — error appears after 10th |
| 2 | Error message is friendly and includes wait time | Message says something like "You're sending messages too quickly. Please wait a moment." |
| 3 | Rate-limited user can resume chatting after the window expires | Wait 60 seconds after being limited — next message succeeds |
| 4 | Per-IP Rack::Attack throttle returns 429 with JSON body | `curl` the endpoint 31+ times in a minute — 429 response with friendly message |
| 5 | Health check endpoint is not rate limited | `/up` always returns 200 regardless of request volume |
| 6 | Authenticated and anonymous users are both rate limited | Test both paths — limits apply equally |
| 7 | Rate limit state does not leak between sessions | Two different sessions from the same IP each get their own per-session budget |

---

## Technical Notes

### Two layers of rate limiting

1. **Rack::Attack (HTTP layer)** — catches rapid HTTP requests before they hit the Rails stack. Protects all endpoints including the initial page load and Action Cable handshake. Uses IP-based throttling.
2. **Channel-level (application layer)** — enforces per-session message limits inside `OnboardingChatChannel#send_message`. This is essential because Action Cable WebSocket messages bypass Rack middleware after the initial handshake.

### Rack::Attack configuration

```ruby
# Throttle all requests by IP (general protection)
throttle("req/ip", limit: 60, period: 1.minute) { |req| req.ip }

# Stricter throttle for onboarding routes
throttle("onboarding/ip", limit: 30, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/onboarding")
end

# Safelist health check
safelist("allow-health-check") { |req| req.path == "/up" }
```

### Channel-level rate limiting

Use `Rails.cache` (Redis-backed) to track message counts per session:

- Key: `rate_limit:chat:session:#{session_id}`
- Increment on each `send_message` call via `Rails.cache.increment`
- TTL: 60 seconds (auto-expires the counter)
- If count exceeds 10, broadcast an error using the existing `Onboarding::ErrorHandler` pattern and return early (do not call the Orchestrator)

Extract this into `Onboarding::RateLimiter` so the logic is testable outside the channel.

### Custom 429 response

Override Rack::Attack's `throttled_responder` to return JSON matching the app's error format:

```ruby
Rack::Attack.throttled_responder = lambda do |request|
  retry_after = (request.env["rack.attack.match_data"] || {})[:period]
  [
    429,
    { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
    [{ error: "Too many requests. Please wait a moment and try again.", retry_after: retry_after }.to_json]
  ]
end
```

### Redis dependency

The app already has `redis` in the Gemfile and uses it for Action Cable. Rack::Attack should use the same Redis instance. Configure via `Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])` or point it at `Rails.cache` if already Redis-backed.

---

## Files to Create

| File | Purpose |
|------|---------|
| `config/initializers/rack_attack.rb` | Rack::Attack throttle rules, safelist, and custom 429 responder |
| `app/services/onboarding/rate_limiter.rb` | Application-level per-session rate limit check (wraps Rails.cache increment with TTL) |
| `test/unit/onboarding/rate_limiter_test.rb` | Unit tests for the rate limiter service |
| `test/integration/rate_limiting_test.rb` | Integration tests for Rack::Attack and channel-level limits |

## Files to Modify

| File | Changes |
|------|---------|
| `Gemfile` | Add `gem "rack-attack"` |
| `app/channels/onboarding_chat_channel.rb` | Call `Onboarding::RateLimiter.check!` at the top of `send_message`; broadcast error and return early if limited |
| `config/application.rb` | Add `config.middleware.use Rack::Attack` if not auto-loaded by the gem |

---

## Files You Should READ Before Coding

1. `app/channels/onboarding_chat_channel.rb` — `send_message` method where channel-level limit is enforced
2. `app/services/onboarding/error_handler.rb` — existing error categorization and broadcast pattern
3. `Gemfile` — current dependencies (redis already present)
4. `config/routes.rb` — routes to protect
5. `config/environments/development.rb` — cache store config (needs Redis for rate limiting to work)

---

## Definition of Done

- [ ] All deliverables checked
- [ ] All acceptance criteria verified
- [ ] `DEVLOG.md` updated with P1-006 entry
- [ ] Feature branch pushed; PR ready for review

---

## Suggested Branch

```bash
git switch -c feature/P1-006-rate-limiting
```

---

## Out of Scope for P1-006

- Per-user rate limits tied to authentication tiers or roles
- Admin UI for adjusting rate limit thresholds at runtime
- IP allowlisting / blocklisting beyond the health check safelist
- DDoS protection (handled at infrastructure / CDN layer)
- LLM token-based cost limiting or budget caps (P5-003)
- CAPTCHA or proof-of-work challenges
- Rate limiting WebSocket connection attempts (only message sends are limited)
