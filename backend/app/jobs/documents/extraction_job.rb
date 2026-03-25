# frozen_string_literal: true

module Documents
  class ExtractionJob < ApplicationJob
    queue_as :default

    def perform(document_id)
      document = Document.find_by(id: document_id)
      return unless document
      return unless document.status == "uploaded"

      service = Documents::ExtractionService.new(document)
      fields = service.extract!

      # Notify the chat channel that extraction is complete
      session = document.onboarding_session
      if session
        OnboardingChatChannel.broadcast_to(session, {
          type: "document_extracted",
          document_id: document.id,
          document_type: document.document_type,
          field_count: fields.size,
          status: document.reload.status
        })
      end
    end
  end
end
