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

ActiveRecord::Schema[8.1].define(version: 2026_11_25_194306) do
  create_table "blocked_names", force: :cascade do |t|
    t.string "term", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["term"], name: "index_blocked_names_on_term", unique: true
  end

  create_table "cryptics", force: :cascade do |t|
    t.string "source_id", null: false
    t.text "statement", null: false
    t.string "enumeration", null: false
    t.string "answer", null: false
    t.json "definitions", default: [], null: false
    t.json "indicators", default: [], null: false
    t.json "material", default: [], null: false
    t.string "cryptic_type", null: false
    t.string "difficulty", null: false
    t.text "help"
    t.text "explanation"
    t.string "author"
    t.string "origin"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "daily_candidate", default: false, null: false
    t.index ["difficulty", "active"], name: "index_cryptics_on_difficulty_and_active"
    t.index ["source_id"], name: "index_cryptics_on_source_id", unique: true
    t.check_constraint "cryptic_type IN ('anagrama', 'oculta', 'charada', 'contenedor', 'inversion', 'supresion', 'homofono', 'doble_definicion', 'iniciales', 'finales', 'sustitucion', 'simbolos', 'combinada')", name: "cryptics_type_check"
    t.check_constraint "difficulty IN ('facil', 'medio', 'avanzado')", name: "cryptics_difficulty_check"
  end

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.string "token", null: false
    t.boolean "blocked", default: false, null: false
    t.integer "current_streak", default: 0, null: false
    t.integer "best_streak", default: 0, null: false
    t.date "last_solved_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower(name)", name: "index_players_on_lower_name", unique: true
    t.index ["token"], name: "index_players_on_token", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "source_url", null: false
    t.text "welcome_text"
    t.string "last_synced_version"
    t.datetime "leaderboard_reset_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "last_synced_url"
  end

  create_table "sync_logs", force: :cascade do |t|
    t.integer "user_id"
    t.string "version"
    t.string "status", null: false
    t.integer "created_count", default: 0, null: false
    t.integer "updated_count", default: 0, null: false
    t.integer "deactivated_count", default: 0, null: false
    t.integer "rejected_count", default: 0, null: false
    t.json "rejections", default: [], null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sync_logs_on_user_id"
    t.check_constraint "status IN ('ok', 'unchanged', 'failed')", name: "sync_logs_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "score_editor", null: false
    t.boolean "active", default: true, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "role IN ('admin', 'score_editor')", name: "users_role_check"
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "sync_logs", "users"
end
