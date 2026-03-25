# frozen_string_literal: true

require "securerandom"

Rails.application.configure do
  config.secret_key_base = ENV["SECRET_KEY_BASE"].presence || "0" * 64
  config.enable_reloading = true
  config.eager_load = ENV["CI"].present?
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=3600" }
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.active_job.queue_adapter = :test
  config.active_storage.service = :test
end
