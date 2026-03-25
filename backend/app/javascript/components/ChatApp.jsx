import React, { useState, useEffect, useRef } from "react"
import { createRoot } from "react-dom/client"
import { createConsumer } from "@rails/actioncable"
import FileUpload from "./FileUpload"

function ChatApp() {
  const rootEl = document.getElementById("chat-root")
  const sessionId = rootEl?.getAttribute("data-session-id")
  const initialMessagesJson = rootEl?.getAttribute("data-initial-messages") || "[]"
  const isCompleted = rootEl?.getAttribute("data-completed") === "true"
  const isResuming = rootEl?.getAttribute("data-resuming") === "true"

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
  const [currentStep, setCurrentStep] = useState(rootEl?.getAttribute("data-current-step") || "")
  const [progress, setProgress] = useState(parseInt(rootEl?.getAttribute("data-progress") || "0", 10))
  const messagesEndRef = useRef(null)
  const subscriptionRef = useRef(null)

  useEffect(() => {
    if (!sessionId) return
    const url = document.querySelector('meta[name="action-cable-url"]')?.content || "/cable"
    const consumer = createConsumer(url)
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
            // Update progress from server
            if (data.current_step) setCurrentStep(data.current_step)
            if (data.progress_percent != null) {
              setProgress(data.progress_percent)
              // Update the progress bar in the ERB-rendered header
              const bar = document.querySelector("[data-progress-bar]")
              if (bar) bar.style.width = `${data.progress_percent}%`
              const label = document.querySelector("[data-progress-label]")
              if (label) label.textContent = `${data.progress_percent}%`
              const stepLabel = document.querySelector("[data-step-label]")
              if (stepLabel) stepLabel.textContent = `Step: ${(data.current_step || "").replace(/_/g, " ")}`
            }
          } else if (data.type === "error") {
            setMessages((prev) => [...prev, {
              id: null,
              role: "error",
              content: data.message || "Something went wrong.",
              retryable: data.retryable !== false
            }])
            setStreamingContent("")
            setIsStreaming(false)
          }
        },
      }
    )
    subscriptionRef.current = sub
    return () => {
      sub.unsubscribe()
      consumer.disconnect()
    }
  }, [sessionId])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages, streamingContent])

  const handleRetry = () => {
    // Find the last user message and resend it
    const lastUserMsg = [...messages].reverse().find((m) => m.role === "user")
    if (!lastUserMsg || !subscriptionRef.current || isStreaming) return
    // Remove the error message
    setMessages((prev) => prev.filter((m) => m.role !== "error"))
    subscriptionRef.current.perform("send_message", { body: lastUserMsg.content })
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    const body = inputValue.trim()
    if (!body || !subscriptionRef.current || isStreaming || isCompleted) return
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

  const emptyState = messages.length === 0 && !streamingContent

  return (
    <div className="flex h-full min-h-0 min-w-0 flex-col bg-white">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {emptyState && !isResuming && (
          <p className="text-center text-[#777777] text-sm font-light pt-8">
            Send a message to start your onboarding.
          </p>
        )}
        {emptyState && isResuming && (
          <p className="text-center text-[#777777] text-sm font-light pt-8">
            Welcome back! Send a message to continue.
          </p>
        )}
        {isCompleted && emptyState && (
          <div className="text-center pt-8">
            <p className="text-[#00C14E] text-lg font-medium">Onboarding Complete</p>
            <p className="text-[#777777] text-sm font-light mt-2">
              You've finished all onboarding steps. Contact HR if you need to update anything.
            </p>
          </div>
        )}
        {messages.map((m) => (
          <div
            key={m.id ?? `msg-${m.role}-${messages.indexOf(m)}`}
            className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}
          >
            {m.role === "error" ? (
              <div className="max-w-[85%] rounded-2xl border border-[#B3014D]/20 bg-[#B3014D]/5 px-4 py-2 text-sm font-light text-[#B3014D]">
                <div className="whitespace-pre-wrap break-words">{m.content}</div>
                {m.retryable && (
                  <button
                    onClick={handleRetry}
                    className="mt-2 text-xs font-medium text-[#6D46DE] hover:opacity-80 underline"
                  >
                    Try again
                  </button>
                )}
              </div>
            ) : (
              <div
                className={`max-w-[85%] rounded-2xl px-4 py-2 text-sm font-light ${
                  m.role === "user"
                    ? "bg-[#6D46DE] text-white"
                    : "bg-[rgba(0,0,0,0.03)] text-[#333333]"
                }`}
              >
                <div className="whitespace-pre-wrap break-words">{m.content}</div>
              </div>
            )}
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
      {currentStep === "document_upload" && !isCompleted && (
        <FileUpload
          sessionId={sessionId}
          onUploadComplete={(doc) => {
            setMessages((prev) => [...prev, {
              id: null,
              role: "assistant",
              content: `Document "${doc.document_type}" uploaded successfully. You can upload more or send a message to continue.`
            }])
          }}
        />
      )}
      {!isCompleted && (
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
      )}
    </div>
  )
}

const container = document.getElementById("chat-root")
if (container) {
  createRoot(container).render(<ChatApp />)
}
