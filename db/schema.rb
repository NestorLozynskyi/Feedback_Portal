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

ActiveRecord::Schema[8.1].define(version: 2026_11_06_120500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_categories_on_lower_name", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "suggestion_id", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.boolean "hidden", default: false, null: false
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["suggestion_id"], name: "index_comments_on_suggestion_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "suggestions", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.bigint "category_id"
    t.string "title", null: false
    t.text "body", null: false
    t.string "kind", null: false
    t.string "status", default: "under_review", null: false
    t.boolean "hidden", default: false, null: false
    t.integer "votes_count", default: 0, null: false
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_suggestions_on_author_id"
    t.index ["category_id"], name: "index_suggestions_on_category_id"
    t.index ["created_at"], name: "index_suggestions_on_created_at"
    t.index ["status"], name: "index_suggestions_on_status"
    t.index ["votes_count"], name: "index_suggestions_on_votes_count"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.boolean "admin", default: false, null: false
    t.boolean "blocked", default: false, null: false
    t.integer "avatar_hue"
    t.index ["admin"], name: "index_users_single_admin", unique: true, where: "admin"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "suggestion_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["suggestion_id"], name: "index_votes_on_suggestion_id"
    t.index ["user_id", "suggestion_id"], name: "index_votes_on_user_id_and_suggestion_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "comments", "suggestions", on_delete: :cascade
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "suggestions", "categories", on_delete: :nullify
  add_foreign_key "suggestions", "users", column: "author_id"
  add_foreign_key "votes", "suggestions", on_delete: :cascade
  add_foreign_key "votes", "users"
end
