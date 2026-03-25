import React, { useState, useEffect, useRef } from "react"
import { createRoot } from "react-dom/client"
import { createConsumer } from "@rails/actioncable"

const DEFAULT_SYSTEM_PROMPT = "You are a helpful onboarding assistant."

function ChatApp() {
  const rootEl = document.getElementById("chat-root")
  const sessionId = rootEl?.getAttribute("data-session-id")
  const initialMessagesJson = rootEl?.getAttribute("data-initial-messages") || "[]"

  const [messages, setMessages] = useState(() => {
    try {
      return JSON.parse(initialMessagesJson)
    } catch {
      return []
    }
  })
  const [streamingContent, setStreamingContent] = useState("")
  const [inputValue, setInputValue] = useState("")
  const [isStreaming, setIsStreaming] = useState(false)
  const [cable, setCable] = useState(null)
  const [sub, setSub] = useState(null)
  const messagesEndRef = useRef(null)
  const subscriptionRef = useRef(null)

  useEffect(() => {
    if (!sessionId) return
    const url = document.querySelector('meta[name="action-cable-url"]')?.content || "/cable"
    const consumer = createConsumer(url)
    setCable(consumer)
    const sub = consumer.subscriptions.create(
      { channel: "OnboardingChatChannel", session_id: sessionId },
      {
        received(data) {
          if (data.type === "start") {
            setIsStreaming(true)
            setStreamingContent("")
          } else if (data.type === "token") {
            setStreamingContent((prev) => prev + (data.content || ""))
          } else if (data.type === "done") {
            setMessages((prev) => [...prev, { id: data.id, role: "assistant", content: data.content || "" }])
            setStreamingContent("")
            setIsStreaming(false)
          } else if (data.type === "error") {
            setMessages((prev) => [...prev, { id: null, role: "assistant", content: data.message || "Something went wrong." }])
            setStreamingContent("")
            setIsStreaming(false)
          }
        },
      }
    )
    subscriptionRef.current = sub
    setSub(sub)
    return () => {
      sub.unsubscribe()
      consumer.disconnect()
    }
  }, [sessionId])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages, streamingContent])

  const handleSubmit = (e) => {
    e.preventDefault()
    const body = inputValue.trim()
    if (!body || !subscriptionRef.current || isStreaming) return
    setInputValue("")
    setMessages((prev) => [...prev, { id: null, role: "user", content: body }])
    subscriptionRef.current.perform("send_message", { body })
  }

  if (!sessionId) {
    return (
      <div className="flex h-full items-center justify-center text-[#777777] font-light">
        Missing session. Refresh the page.
      </div>
    )
  }

  return (
    <div className="flex h-full min-h-0 min-w-0 flex-col bg-white sm:min-h-[400px]">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && !streamingContent && (
          <p className="text-center text-[#777777] text-sm font-light pt-8">
            Send a message to start your onboarding.
          </p>
        )}
        {messages.map((m) => (
          <div
            key={m.id ?? `msg-${m.role}-${messages.indexOf(m)}`}
            className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}
          >
            <div
              className={`max-w-[85%] rounded-2xl px-4 py-2 text-sm font-light ${
                m.role === "user"
                  ? "bg-[#6D46DE] text-white"
                  : "bg-[rgba(0,0,0,0.03)] text-[#333333]"
              }`}
            >
              <div className="whitespace-pre-wrap break-words">{m.content}</div>
            </div>
          </div>
        ))}
        {streamingContent && (
          <div className="flex justify-start">
            <div className="max-w-[85%] rounded-2xl bg-[rgba(0,0,0,0.03)] px-4 py-2 text-sm font-light text-[#333333]">
              <div className="whitespace-pre-wrap break-words">{streamingContent}</div>
            </div>
          </div>
        )}
        {isStreaming && !streamingContent && (
          <div className="flex justify-start">
            <div className="rounded-2xl bg-[rgba(0,0,0,0.03)] px-4 py-2 text-sm font-light text-[#777777]">
              <span className="animate-pulse">...</span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>
      <form onSubmit={handleSubmit} className="border-t border-[#E0E0E0] p-3">
        <div className="flex gap-2">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            placeholder="Type a message..."
            className="flex-1 rounded-pill border border-[#E0E0E0] px-4 py-2 text-sm font-light focus:border-[#6D46DE] focus:outline-none focus:ring-1 focus:ring-[#6D46DE]"
            disabled={isStreaming}
            autoComplete="off"
          />
          <button
            type="submit"
            disabled={isStreaming || !inputValue.trim()}
            className="rounded-pill bg-[#6D46DE] px-5 py-2 text-sm font-light text-white hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Send
          </button>
        </div>
      </form>
    </div>
  )
}

const container = document.getElementById("chat-root")
if (container) {
  createRoot(container).render(<ChatApp />)
}
