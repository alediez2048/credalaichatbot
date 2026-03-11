import React from "react"
import { createRoot } from "react-dom/client"

function ChatApp() {
  return (
    <div className="flex items-center justify-center h-full min-h-[400px] text-gray-500">
      Chat loading...
    </div>
  )
}

const container = document.getElementById("chat-root")
if (container) {
  createRoot(container).render(<ChatApp />)
}
