# frozen_string_literal: true

require_relative "boot"

# Frameworks — Active Storage added in Phase 2
require "rails"
%w[
  active_record/railtie
  active_storage/engine
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  rails/test_unit/railtie
  sprockets/railtie
].each { |r| require r }

Bundler.require(*Rails.groups)

module OnboardingAssistant
  class Application < Rails::Application
    config.load_defaults 7.2
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = false
    config.time_zone = "UTC"
    config.generators.system_tests = nil
  end
end
