# frozen_string_literal: true

module LLM
  class ContextBuilder
    # @param system_prompt [String]
    # @param history [Array<Hash>] array of { role:, content: } (e.g. from Message records)
    # @param current_message [String] latest user message
    # @return [Array<Hash>] messages in OpenAI format (role + content)
    def self.build(system_prompt:, history: [], current_message:)
      messages = []

      messages << { role: "system", content: system_prompt } if system_prompt.present?

      history.each do |h|
        role = h[:role] || h["role"]
        content = h[:content] || h["content"]
        next if role.blank? || content.blank?
        messages << { role: role.to_s, content: content.to_s }
      end

      messages << { role: "user", content: current_message.to_s } if current_message.present?

      messages
    end
  end
end
