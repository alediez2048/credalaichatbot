# frozen_string_literal: true

module Api
  class ExtractedFieldsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # PATCH /api/extracted_fields/:id
    def update
      field = ExtractedField.find_by(id: params[:id])
      unless field
        render json: { error: "Field not found" }, status: :not_found
        return
      end

      if params[:confirmed] == true || params[:confirmed] == "true"
        field.update!(status: "confirmed")
      elsif params[:value].present?
        field.update!(value: params[:value], status: "corrected")
      else
        render json: { error: "Provide 'confirmed: true' or a new 'value'" }, status: :unprocessable_entity
        return
      end

      render json: {
        id: field.id,
        field_name: field.field_name,
        value: field.value,
        confidence: field.confidence,
        status: field.status
      }
    end
  end
end
