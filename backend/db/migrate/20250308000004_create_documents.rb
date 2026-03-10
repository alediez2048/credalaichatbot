# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :documents do |t|
      t.references :onboarding_session, null: false, foreign_key: true
      t.string :document_type
      t.string :storage_key
      t.string :content_type
      t.bigint :byte_size
      t.string :status, default: "uploaded"
      t.timestamps
    end
  end
end
