# frozen_string_literal: true

class CreateExtractedFields < ActiveRecord::Migration[7.2]
  def change
    create_table :extracted_fields do |t|
      t.references :document, null: false, foreign_key: true
      t.string :field_name, null: false
      t.text :value
      t.decimal :confidence, precision: 5, scale: 4
      t.string :status, default: "pending"
      t.timestamps
    end

    add_index :extracted_fields, [:document_id, :field_name]
  end
end
