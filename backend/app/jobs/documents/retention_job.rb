# frozen_string_literal: true

module Documents
  class RetentionJob < ApplicationJob
    queue_as :default

    def perform
      deleted = Documents::RetentionService.purge_expired!
      Rails.logger.info "[RetentionJob] Purged #{deleted} expired documents"
    end
  end
end
