# frozen_string_literal: true

# Subscribable at stream_from "ping" — used to verify Action Cable in browser console:
# consumer.subscriptions.create("PingChannel", {})
class PingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ping"
  end
end
