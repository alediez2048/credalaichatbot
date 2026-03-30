# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock" # Object#stub for class/instance method stubs in tests

module ActiveSupport
  class TestCase
    # Fork-based parallel tests often segfault on macOS after native code loads
    # (Objective-C runtime, Kerberos/GSS plugins, pg, etc.). CI is typically Linux.
    parallelize(workers: :number_of_processors) if ENV["CI"].present?
  end
end
