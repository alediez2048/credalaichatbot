# frozen_string_literal: true

module Tools
  class Router
    def initialize(validator: nil)
      @validator = validator || SchemaValidator.new
      @handlers = build_handlers
    end

    # @param tool_name [String]
    # @param arguments [Hash] tool call arguments (string keys from OpenAI)
    # @param context [Hash] optional context (e.g. { session: OnboardingSession })
    # @return [Hash] result to send back to the LLM (e.g. { success: true, data: ... })
    def call(tool_name, arguments, context: {})
      args = arguments.is_a?(String) ? parse_arguments(arguments) : (arguments || {}).stringify_keys
      result = @validator.validate(tool_name, args)
      unless result[:valid]
        return { success: false, error: result[:errors].join("; ") }
      end

      handler = @handlers[tool_name.to_s]
      unless handler
        return { success: false, error: "No handler for tool: #{tool_name}" }
      end

      handler.call(args, **context)
    end

    def tool_names
      @validator.tool_names
    end

    private

    def parse_arguments(json_string)
      JSON.parse(json_string.to_s).stringify_keys
    rescue JSON::ParserError
      {}
    end

    def build_handlers
      stubs = @validator.tool_names.to_h { |name| [name, stub_handler(name)] }
      stubs.merge(
        "startOnboarding" => method(:handle_start_onboarding),
        "saveOnboardingProgress" => method(:handle_save_progress),
        "getOnboardingState" => method(:handle_get_state),
        "extractDocumentData" => method(:handle_extract_document),
        "validateExtractedData" => method(:handle_validate_fields),
        "getAvailableSlots" => method(:handle_get_slots),
        "bookAppointment" => method(:handle_book_appointment)
      )
    end

    def stub_handler(name)
      ->(_args, **_ctx) { { success: true, data: { tool: name, message: "This feature is coming soon." } } }
    end

    def handle_start_onboarding(args, session: nil, **_)
      if session
        session.update!(current_step: "welcome") if session.current_step.blank?
        { success: true, data: { session_id: session.id, current_step: session.current_step } }
      else
        { success: true, data: { message: "Session not available." } }
      end
    end

    def handle_save_progress(args, session: nil, **_)
      if session
        data = args["data"] || {}
        merged = (session.metadata || {}).merge(data)
        session.update!(metadata: merged)
        { success: true, data: { step: args["step"] || session.current_step, saved_fields: data.keys } }
      else
        { success: true, data: { message: "Session not available." } }
      end
    end

    def handle_get_state(args, session: nil, **_)
      if session
        { success: true, data: { current_step: session.current_step, progress_percent: session.progress_percent, collected_data: session.metadata } }
      else
        { success: true, data: { message: "Session not available." } }
      end
    end

    def handle_validate_fields(args, session: nil, **_)
      document_id = args["document_id"]
      document = Document.find_by(id: document_id)

      if document
        summary = Documents::FieldValidator.build_review_summary(document)
        result = Documents::FieldValidator.classify_document(document)
        { success: true, data: {
          summary: summary,
          auto_accepted: result[:auto_accepted].size,
          needs_review: result[:needs_review].size,
          needs_correction: result[:needs_correction].size
        }}
      else
        { success: false, error: "Document not found." }
      end
    end

    def handle_get_slots(args, session: nil, **_)
      service_type = args["serviceType"]
      slots = Scheduling::SlotRecommender.recommend(service_type: service_type, limit: 5)
      formatted = Scheduling::SlotRecommender.format_for_llm(slots)
      { success: true, data: { slots: formatted, count: formatted.size } }
    end

    def handle_book_appointment(args, session: nil, **_)
      slot_id = args["slotId"]
      session_id = session&.id || args["userId"]

      begin
        booking = Scheduling::SlotManager.book!(slot_id, session_id)
        { success: true, data: {
          booking_id: booking.id,
          starts_at: booking.starts_at.to_s,
          service_type: booking.service_type,
          status: booking.status
        }}
      rescue Scheduling::SlotManager::SlotFullError => e
        { success: false, error: e.message }
      rescue Scheduling::SlotManager::SlotNotFoundError => e
        { success: false, error: e.message }
      end
    end

    def handle_extract_document(args, session: nil, **_)
      document_id = args["document_id"] || args["imageFile"]
      document = Document.find_by(id: document_id)

      if document
        Documents::ExtractionJob.perform_later(document.id)
        { success: true, data: { status: "processing", document_id: document.id, message: "Document is being processed. You'll be notified when extraction is complete." } }
      else
        { success: false, error: "Document not found." }
      end
    end
  end
end
