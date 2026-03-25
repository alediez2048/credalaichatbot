# frozen_string_literal: true

module Sentiment
  class Analyzer
    VALID_LABELS = SentimentReading::LABELS
    WINDOW_SIZE = 5

    class << self
      # Analyze sentiment from recent messages using LLM
      def analyze(session, chat_service: nil)
        messages = session.messages.order(:created_at).last(WINDOW_SIZE)
        return default_result if messages.empty?

        service = chat_service || LLM::ChatService.new
        prompt_messages = [
          { role: "system", content: build_prompt(messages.map { |m| { role: m.role, content: m.content } }) }
        ]

        response = service.chat(messages: prompt_messages, tools: [])
        parse_response(response)
      end

      def build_prompt(messages)
        conversation = messages.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n")

        <<~PROMPT
          Analyze the sentiment of the USER messages in this conversation. Focus only on the user's emotional state, not the assistant's.

          Conversation:
          #{conversation}

          Classify the user's current sentiment as exactly one of: positive, neutral, confused, frustrated, anxious

          Return your response as a JSON object with this exact structure:
          {
            "label": "one of the five labels above",
            "confidence": 0.85,
            "signals": ["up to 3 short phrases explaining why you chose this label"]
          }

          Return ONLY the JSON object, no other text.
        PROMPT
      end

      def parse_response(response)
        content = response.dig("choices", 0, "message", "content").to_s
        parsed = JSON.parse(content)

        label = parsed["label"].to_s.downcase
        label = "neutral" unless VALID_LABELS.include?(label)

        {
          label: label,
          confidence: parsed["confidence"].to_f.clamp(0.0, 1.0),
          signals: Array(parsed["signals"]).first(3)
        }
      rescue JSON::ParserError
        default_result
      end

      def default_result
        { label: "neutral", confidence: 0.5, signals: [] }
      end
    end
  end
end
