# frozen_string_literal: true

# P0-005: Langfuse observability. No-op when LANGFUSE_SECRET_KEY is blank.
if ENV["LANGFUSE_SECRET_KEY"].to_s.strip.present?
  require "langfuse"

  Langfuse.configure do |config|
    config.public_key = ENV["LANGFUSE_PUBLIC_KEY"].to_s.strip.presence
    config.secret_key = ENV["LANGFUSE_SECRET_KEY"].to_s.strip
    config.host = ENV.fetch("LANGFUSE_HOST", "https://us.cloud.langfuse.com").strip
  end
end
