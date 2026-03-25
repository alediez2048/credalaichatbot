# frozen_string_literal: true

require "test_helper"

module LLM
  class ChatServiceStreamTest < ActiveSupport::TestCase
    test "stream_chat when client is nil yields error message once" do
      service = ChatService.new(openai_client: nil)
      service.instance_variable_set(:@client, nil)  # force no client so we never hit the API
      chunks = []
      service.stream_chat(messages: [{ role: "user", content: "Hi" }]) { |c| chunks << c }
      assert_equal 1, chunks.size, "expected one chunk when client is nil"
      assert_includes chunks.first, "OPENAI_API_KEY"
    end

    test "stream_chat with stub client yields content deltas" do
      stub_chunks = [
        { "choices" => [{ "delta" => { "content" => "Hello" } }] },
        { "choices" => [{ "delta" => { "content" => " " } }] },
        { "choices" => [{ "delta" => { "content" => "world" } }] },
      ]
      stub_stream = stub_chunks.each
      stub_completions = Object.new
      stub_completions.define_singleton_method(:stream_raw) { |_params| stub_stream }
      stub_chat = Object.new
      stub_chat.define_singleton_method(:completions) { stub_completions }
      stub_client = Object.new
      stub_client.define_singleton_method(:chat) { stub_chat }

      service = ChatService.new(openai_client: stub_client)
      chunks = []
      service.stream_chat(messages: [{ role: "user", content: "Hi" }]) { |c| chunks << c }
      assert_equal 2, chunks.size, "space chunk is skipped by present? (blank)"
      assert_equal "Hello", chunks[0]
      assert_equal "world", chunks[1]
    end
  end
end
