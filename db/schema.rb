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

ActiveRecord::Schema[8.0].define(version: 2026_10_08_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "document_deliveries", force: :cascade do |t|
    t.bigint "rep_id", null: false
    t.bigint "onboarding_document_id", null: false
    t.string "recipient_email", null: false
    t.string "status", default: "queued", null: false
    t.datetime "sent_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_document_id"], name: "index_document_deliveries_on_onboarding_document_id"
    t.index ["rep_id"], name: "index_document_deliveries_on_rep_id"
    t.index ["status"], name: "index_document_deliveries_on_status"
  end

  create_table "manager_teams", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_manager_teams_on_team_id"
    t.index ["user_id", "team_id"], name: "index_manager_teams_on_user_id_and_team_id", unique: true
    t.index ["user_id"], name: "index_manager_teams_on_user_id"
  end

  create_table "markets", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_markets_on_name", unique: true
  end

  create_table "onboarding_documents", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "body", null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "send_by_default", default: true, null: false
    t.boolean "required", default: false, null: false
    t.index ["deleted_at"], name: "index_onboarding_documents_on_deleted_at"
  end

  create_table "permissions", force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.string "action", null: false
    t.boolean "allowed", default: false, null: false
    t.string "description", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id", "user_id", "action"], name: "index_permissions_on_scope_and_action", unique: true, nulls_not_distinct: true
    t.index ["role_id"], name: "index_permissions_on_role_id"
    t.index ["user_id"], name: "index_permissions_on_user_id"
  end

  create_table "reps", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.date "start_date"
    t.string "market"
    t.text "notes"
    t.string "status", default: "pending", null: false
    t.bigint "recruited_by_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "shirt_size"
    t.date "end_date"
    t.string "drivers_license_number"
    t.boolean "active", default: true, null: false
    t.boolean "onboarding_completed", default: false, null: false
    t.index ["deleted_at"], name: "index_reps_on_deleted_at"
    t.index ["email"], name: "index_reps_on_email"
    t.index ["recruited_by_id"], name: "index_reps_on_recruited_by_id"
    t.index ["status"], name: "index_reps_on_status"
    t.index ["user_id"], name: "index_reps_on_user_id", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_roles_on_code", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "jti", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.bigint "role_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "level"
    t.string "housing"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "document_deliveries", "onboarding_documents"
  add_foreign_key "document_deliveries", "reps"
  add_foreign_key "manager_teams", "teams"
  add_foreign_key "manager_teams", "users"
  add_foreign_key "permissions", "roles"
  add_foreign_key "permissions", "users"
  add_foreign_key "reps", "users"
  add_foreign_key "reps", "users", column: "recruited_by_id"
  add_foreign_key "users", "roles"
end
