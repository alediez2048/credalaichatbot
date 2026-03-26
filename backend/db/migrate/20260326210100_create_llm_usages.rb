class CreateLLMUsages < ActiveRecord::Migration[7.2]
  def change
    create_table :llm_usages do |t|
      t.references :onboarding_session, null: false, foreign_key: true
      t.string :model, null: false
      t.integer :prompt_tokens, default: 0
      t.integer :completion_tokens, default: 0
      t.integer :total_tokens, default: 0
      t.decimal :cost_usd, precision: 10, scale: 6, default: 0

      t.timestamps
    end

    add_index :llm_usages, :created_at
  end
end
