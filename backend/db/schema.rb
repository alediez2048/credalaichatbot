# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_03_08_000007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "onboarding_session_id"
    t.string "action", null: false
    t.string "resource_type"
    t.string "resource_id"
    t.jsonb "payload", default: {}
    t.string "trace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_session_id"], name: "index_audit_logs_on_onboarding_session_id"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["trace_id"], name: "index_audit_logs_on_trace_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "onboarding_session_id", null: false
    t.datetime "starts_at", null: false
    t.integer "duration_minutes", default: 30
    t.string "service_type"
    t.string "status", default: "confirmed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_session_id"], name: "index_bookings_on_onboarding_session_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "onboarding_session_id", null: false
    t.string "document_type"
    t.string "storage_key"
    t.string "content_type"
    t.bigint "byte_size"
    t.string "status", default: "uploaded"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_session_id"], name: "index_documents_on_onboarding_session_id"
  end

  create_table "extracted_fields", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "field_name", null: false
    t.text "value"
    t.decimal "confidence", precision: 5, scale: 4
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "field_name"], name: "index_extracted_fields_on_document_id_and_field_name"
    t.index ["document_id"], name: "index_extracted_fields_on_document_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "onboarding_session_id", null: false
    t.string "role", null: false
    t.text "content"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_session_id", "created_at"], name: "index_messages_on_onboarding_session_id_and_created_at"
    t.index ["onboarding_session_id"], name: "index_messages_on_onboarding_session_id"
  end

  create_table "onboarding_sessions", force: :cascade do |t|
    t.bigint "user_id"
    t.string "anonymous_token"
    t.string "current_step"
    t.integer "progress_percent", default: 0
    t.string "status", default: "active"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["anonymous_token"], name: "index_onboarding_sessions_on_anonymous_token", unique: true, where: "(anonymous_token IS NOT NULL)"
    t.index ["user_id"], name: "index_onboarding_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "audit_logs", "onboarding_sessions"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "bookings", "onboarding_sessions"
  add_foreign_key "documents", "onboarding_sessions"
  add_foreign_key "extracted_fields", "documents"
  add_foreign_key "messages", "onboarding_sessions"
  add_foreign_key "onboarding_sessions", "users"
end
