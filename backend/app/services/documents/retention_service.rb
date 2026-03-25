# frozen_string_literal: true

module Documents
  class RetentionService
    DEFAULT_RETENTION_DAYS = 90

    class << self
      # Delete documents older than retention_days
      # @return [Integer] number of documents deleted
      def purge_expired!(retention_days: nil)
        days = retention_days || ENV.fetch("DOCUMENT_RETENTION_DAYS", DEFAULT_RETENTION_DAYS).to_i
        cutoff = days.days.ago

        expired = Document.where("created_at < ?", cutoff)
        count = expired.count

        expired.find_each do |doc|
          doc.file.purge if doc.file.attached?
          AuditLogger.log(
            action: "document_retention_delete",
            session: doc.onboarding_session,
            resource: doc,
            payload: { document_type: doc.document_type, age_days: ((Time.current - doc.created_at) / 1.day).round }
          )
          doc.destroy!
        end

        count
      end
    end
  end
end
