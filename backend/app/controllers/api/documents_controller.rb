# frozen_string_literal: true

module Api
  class DocumentsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      session_record = OnboardingSession.find_by(id: params[:session_id])
      unless session_record
        render json: { error: "Session not found" }, status: :not_found
        return
      end

      validation = Documents::UploadValidator.validate(params[:file])
      unless validation[:valid]
        render json: { error: validation[:errors].join(" ") }, status: :unprocessable_entity
        return
      end

      file = params[:file]
      document = session_record.documents.create!(
        document_type: params[:document_type] || "unknown",
        content_type: file.content_type,
        byte_size: file.size,
        status: "uploaded"
      )
      document.file.attach(file)

      # Enqueue extraction job
      Documents::ExtractionJob.perform_later(document.id)

      render json: {
        id: document.id,
        document_type: document.document_type,
        content_type: document.content_type,
        byte_size: document.byte_size,
        status: document.status
      }, status: :created
    end
  end
end
