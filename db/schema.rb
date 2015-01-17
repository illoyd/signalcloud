# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150117090515) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "memberships", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "user_id"
    t.boolean  "administrator",        default: false, null: false
    t.boolean  "developer",            default: false, null: false
    t.boolean  "billing_liaison",      default: false, null: false
    t.boolean  "conversation_manager", default: false, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "memberships", ["team_id"], name: "index_memberships_on_team_id", using: :btree
  add_index "memberships", ["user_id"], name: "index_memberships_on_user_id", using: :btree

  create_table "phone_book_entries", force: :cascade do |t|
    t.integer  "phone_book_id"
    t.integer  "phone_number_id"
    t.string   "country"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "phone_book_entries", ["phone_book_id"], name: "index_phone_book_entries_on_phone_book_id", using: :btree
  add_index "phone_book_entries", ["phone_number_id"], name: "index_phone_book_entries_on_phone_number_id", using: :btree

  create_table "phone_books", force: :cascade do |t|
    t.integer  "team_id"
    t.string   "workflow_state"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "phone_books", ["team_id"], name: "index_phone_books_on_team_id", using: :btree
  add_index "phone_books", ["workflow_state"], name: "index_phone_books_on_workflow_state", using: :btree

  create_table "phone_numbers", force: :cascade do |t|
    t.string   "type"
    t.integer  "team_id",        null: false
    t.string   "workflow_state"
    t.string   "number",         null: false
    t.string   "provider_sid"
    t.text     "description"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "phone_numbers", ["number"], name: "index_phone_numbers_on_number", using: :btree
  add_index "phone_numbers", ["team_id"], name: "index_phone_numbers_on_team_id", using: :btree
  add_index "phone_numbers", ["type"], name: "index_phone_numbers_on_type", using: :btree
  add_index "phone_numbers", ["workflow_state"], name: "index_phone_numbers_on_workflow_state", using: :btree

  create_table "teams", force: :cascade do |t|
    t.integer  "owner_id"
    t.string   "workflow_state"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "teams", ["owner_id"], name: "index_teams_on_owner_id", using: :btree
  add_index "teams", ["workflow_state"], name: "index_teams_on_workflow_state", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "name"
    t.string   "nickname"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "memberships", "teams"
  add_foreign_key "memberships", "users"
  add_foreign_key "phone_book_entries", "phone_books"
  add_foreign_key "phone_book_entries", "phone_numbers"
  add_foreign_key "phone_books", "teams"
  add_foreign_key "phone_numbers", "teams"
end
