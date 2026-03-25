# frozen_string_literal: true

require "test_helper"

module Documents
  class PiiTest < ActiveSupport::TestCase
    # --- PII Redactor ---

    test "redacts SSN patterns" do
      text = "SSN: 123-45-6789"
      assert_equal "SSN: ***-**-****", Documents::PiiRedactor.redact(text)
    end

    test "redacts date of birth patterns" do
      text = "DOB: 1990-01-15"
      result = Documents::PiiRedactor.redact(text)
      assert_not_includes result, "1990-01-15"
    end

    test "redacts email addresses" do
      text = "Email: jane@example.com"
      result = Documents::PiiRedactor.redact(text)
      assert_not_includes result, "jane@example.com"
    end

    test "handles text with no PII" do
      text = "This is a normal message."
      assert_equal text, Documents::PiiRedactor.redact(text)
    end

    test "handles nil input" do
      assert_equal "", Documents::PiiRedactor.redact(nil)
    end

    # --- Retention Service ---

    test "deletes documents older than retention period" do
      session = OnboardingSession.create!(status: "active")
      old_doc = session.documents.create!(document_type: "test", status: "extracted", content_type: "image/png", byte_size: 100, created_at: 100.days.ago)
      new_doc = session.documents.create!(document_type: "test", status: "extracted", content_type: "image/png", byte_size: 100, created_at: 1.day.ago)

      deleted = Documents::RetentionService.purge_expired!(retention_days: 90)

      assert_not Document.exists?(old_doc.id)
      assert Document.exists?(new_doc.id)
      assert_equal 1, deleted
    end

    test "does not delete documents within retention period" do
      session = OnboardingSession.create!(status: "active")
      doc = session.documents.create!(document_type: "test", status: "extracted", content_type: "image/png", byte_size: 100, created_at: 10.days.ago)

      deleted = Documents::RetentionService.purge_expired!(retention_days: 90)

      assert Document.exists?(doc.id)
      assert_equal 0, deleted
    end

    # --- Auditable ---

    test "creates audit log entry" do
      session = OnboardingSession.create!(status: "active")
      Documents::AuditLogger.log(
        action: "document_upload",
        session: session,
        resource: nil,
        payload: { filename: "test.png" }
      )

      log = AuditLog.last
      assert_equal "document_upload", log.action
      assert_equal session.id, log.onboarding_session_id
      assert_equal "test.png", log.payload["filename"]
    end
  end
end
