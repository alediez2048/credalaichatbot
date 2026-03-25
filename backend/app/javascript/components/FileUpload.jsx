import React, { useState, useRef } from "react"

const ALLOWED_TYPES = ["image/png", "image/jpeg", "application/pdf"]
const MAX_SIZE = 10 * 1024 * 1024 // 10 MB

export default function FileUpload({ sessionId, onUploadComplete }) {
  const [dragOver, setDragOver] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState(0)
  const [error, setError] = useState(null)
  const [success, setSuccess] = useState(null)
  const fileInputRef = useRef(null)

  const validateFile = (file) => {
    if (!ALLOWED_TYPES.includes(file.type)) {
      return "Unsupported file type. Please upload PNG, JPEG, or PDF."
    }
    if (file.size > MAX_SIZE) {
      return `File too large (${(file.size / 1024 / 1024).toFixed(1)} MB). Maximum is 10 MB.`
    }
    return null
  }

  const uploadFile = async (file) => {
    const validationError = validateFile(file)
    if (validationError) {
      setError(validationError)
      return
    }

    setError(null)
    setSuccess(null)
    setUploading(true)
    setProgress(0)

    const formData = new FormData()
    formData.append("file", file)
    formData.append("session_id", sessionId)
    formData.append("document_type", guessDocType(file.name))

    try {
      const xhr = new XMLHttpRequest()
      xhr.upload.addEventListener("progress", (e) => {
        if (e.lengthComputable) setProgress(Math.round((e.loaded / e.total) * 100))
      })

      const result = await new Promise((resolve, reject) => {
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve(JSON.parse(xhr.responseText))
          } else {
            const body = JSON.parse(xhr.responseText)
            reject(new Error(body.error || "Upload failed"))
          }
        }
        xhr.onerror = () => reject(new Error("Network error"))
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
        xhr.open("POST", "/api/documents")
        if (csrfToken) xhr.setRequestHeader("X-CSRF-Token", csrfToken)
        xhr.send(formData)
      })

      setSuccess(`${file.name} uploaded successfully.`)
      if (onUploadComplete) onUploadComplete(result)
    } catch (err) {
      setError(err.message)
    } finally {
      setUploading(false)
      setProgress(0)
    }
  }

  const guessDocType = (filename) => {
    const lower = filename.toLowerCase()
    if (lower.includes("license") || lower.includes("dl")) return "drivers_license"
    if (lower.includes("w4") || lower.includes("w-4")) return "w4"
    if (lower.includes("passport")) return "passport"
    return "other"
  }

  const handleDrop = (e) => {
    e.preventDefault()
    setDragOver(false)
    const file = e.dataTransfer.files[0]
    if (file) uploadFile(file)
  }

  const handleFileSelect = (e) => {
    const file = e.target.files[0]
    if (file) uploadFile(file)
  }

  return (
    <div className="px-4 py-3">
      <div
        onDragOver={(e) => { e.preventDefault(); setDragOver(true) }}
        onDragLeave={() => setDragOver(false)}
        onDrop={handleDrop}
        className={`rounded-2xl border-2 border-dashed p-6 text-center transition-colors ${
          dragOver ? "border-[#6D46DE] bg-[#6D46DE]/5" : "border-[#E0E0E0] bg-[rgba(0,0,0,0.01)]"
        }`}
      >
        <p className="text-sm font-light text-[#555555]">
          {uploading ? `Uploading... ${progress}%` : "Drag and drop a document here, or"}
        </p>
        {uploading && (
          <div className="mt-2 h-2 w-full rounded-full bg-[#E0E0E0]">
            <div className="h-2 rounded-full bg-[#6D46DE] transition-all" style={{ width: `${progress}%` }} />
          </div>
        )}
        {!uploading && (
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="mt-2 rounded-pill bg-[#6D46DE] px-4 py-1.5 text-sm font-light text-white hover:opacity-90"
          >
            Choose file
          </button>
        )}
        <input
          ref={fileInputRef}
          type="file"
          accept=".png,.jpg,.jpeg,.pdf"
          onChange={handleFileSelect}
          className="hidden"
        />
        <p className="mt-2 text-xs font-light text-[#777777]">PNG, JPEG, or PDF — max 10 MB</p>
      </div>
      {error && <p className="mt-2 text-sm font-light text-[#B3014D]">{error}</p>}
      {success && <p className="mt-2 text-sm font-light text-[#00C14E]">{success}</p>}
    </div>
  )
}
