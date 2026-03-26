# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.force_ssl = true

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.active_job.queue_adapter = :sidekiq

  # Gzip compression
  config.middleware.use Rack::Deflater

  # Action Cable — restrict origins to production domain
  config.action_cable.allowed_request_origins = [
    ENV.fetch("APP_URL", "https://onboarding-assistant.onrender.com"),
    /https:\/\/.*\.onrender\.com/
  ]
end
