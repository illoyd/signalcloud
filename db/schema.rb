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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121220210403) do

  create_table "account_plans", :force => true do |t|
    t.string   "label",                                                         :null => false
    t.boolean  "default",                                    :default => false, :null => false
    t.decimal  "month",        :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "phone_add",    :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "phone_mult",   :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "call_in_add",  :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "call_in_mult", :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "sms_in_add",   :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "sms_in_mult",  :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "sms_out_add",  :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.decimal  "sms_out_mult", :precision => 6, :scale => 4, :default => 0.0,   :null => false
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
  end

  create_table "accounts", :force => true do |t|
    t.string   "account_sid",                                                                 :null => false
    t.string   "auth_token",                                                                  :null => false
    t.string   "label",                                                                       :null => false
    t.decimal  "balance",                      :precision => 8, :scale => 4, :default => 0.0, :null => false
    t.integer  "account_plan_id",                                                             :null => false
    t.string   "encrypted_twilio_account_sid"
    t.string   "encrypted_twilio_auth_token"
    t.string   "twilio_application_sid"
    t.text     "description"
    t.datetime "created_at",                                                                  :null => false
    t.datetime "updated_at",                                                                  :null => false
  end

  add_index "accounts", ["account_sid"], :name => "index_accounts_on_account_sid", :unique => true
  add_index "accounts", ["encrypted_twilio_account_sid"], :name => "index_accounts_on_encrypted_twilio_account_sid"
  add_index "accounts", ["label"], :name => "index_accounts_on_label"

  create_table "appliances", :force => true do |t|
    t.integer  "account_id",                                             :null => false
    t.integer  "phone_directory_id",                                     :null => false
    t.string   "label",                                                  :null => false
    t.integer  "seconds_to_live",                     :default => 180,   :null => false
    t.boolean  "default",                             :default => false, :null => false
    t.boolean  "active",                              :default => true,  :null => false
    t.string   "encrypted_question"
    t.string   "encrypted_expected_confirmed_answer"
    t.string   "encrypted_expected_denied_answer"
    t.string   "encrypted_confirmed_reply"
    t.string   "encrypted_denied_reply"
    t.string   "encrypted_failed_reply"
    t.string   "encrypted_expired_reply"
    t.text     "description"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  add_index "appliances", ["account_id"], :name => "index_appliances_on_account_id"
  add_index "appliances", ["default"], :name => "index_appliances_on_default"
  add_index "appliances", ["phone_directory_id"], :name => "index_appliances_on_phone_directory_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "messages", :force => true do |t|
    t.integer  "ticket_id",                                                                               :null => false
    t.string   "twilio_sid",                 :limit => 34
    t.string   "message_kind",               :limit => 1
    t.integer  "status",                     :limit => 2,                                :default => 0,   :null => false
    t.datetime "sent_at"
    t.decimal  "provider_cost",                            :precision => 6, :scale => 4, :default => 0.0, :null => false
    t.decimal  "our_cost",                                 :precision => 6, :scale => 4, :default => 0.0, :null => false
    t.text     "encrypted_payload"
    t.text     "encrypted_callback_payload"
    t.datetime "created_at",                                                                              :null => false
    t.datetime "updated_at",                                                                              :null => false
  end

  add_index "messages", ["message_kind"], :name => "index_messages_on_message_kind"
  add_index "messages", ["status"], :name => "index_messages_on_status"
  add_index "messages", ["ticket_id"], :name => "index_messages_on_ticket_id"
  add_index "messages", ["updated_at"], :name => "index_messages_on_updated_at"

  create_table "phone_directories", :force => true do |t|
    t.integer  "account_id",  :null => false
    t.string   "label",       :null => false
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "phone_directories", ["account_id"], :name => "index_phone_directories_on_account_id"

  create_table "phone_directory_entries", :force => true do |t|
    t.integer  "phone_directory_id", :null => false
    t.integer  "phone_number_id",    :null => false
    t.string   "country"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "phone_directory_entries", ["country"], :name => "index_phone_directory_entries_on_country"
  add_index "phone_directory_entries", ["phone_directory_id"], :name => "index_phone_directory_entries_on_phone_directory_id"
  add_index "phone_directory_entries", ["phone_number_id"], :name => "index_phone_directory_entries_on_phone_number_id"

  create_table "phone_numbers", :force => true do |t|
    t.integer  "account_id",                                                             :null => false
    t.string   "encrypted_number",                                                       :null => false
    t.string   "twilio_phone_number_sid",                                                :null => false
    t.decimal  "provider_cost",           :precision => 6, :scale => 4, :default => 0.0, :null => false
    t.decimal  "our_cost",                :precision => 6, :scale => 4, :default => 0.0, :null => false
    t.datetime "created_at",                                                             :null => false
    t.datetime "updated_at",                                                             :null => false
  end

  add_index "phone_numbers", ["account_id"], :name => "index_phone_numbers_on_account_id"
  add_index "phone_numbers", ["encrypted_number"], :name => "index_phone_numbers_on_encrypted_number"

  create_table "tickets", :force => true do |t|
    t.integer  "appliance_id",                                                    :null => false
    t.integer  "status",                              :limit => 2, :default => 0, :null => false
    t.string   "encrypted_from_number",                                           :null => false
    t.string   "encrypted_to_number",                                             :null => false
    t.datetime "expiry",                                                          :null => false
    t.string   "encrypted_question",                                              :null => false
    t.string   "encrypted_expected_confirmed_answer",                             :null => false
    t.string   "encrypted_expected_denied_answer",                                :null => false
    t.string   "encrypted_actual_answer"
    t.string   "encrypted_confirmed_reply",                                       :null => false
    t.string   "encrypted_denied_reply",                                          :null => false
    t.string   "encrypted_failed_reply",                                          :null => false
    t.string   "encrypted_expired_reply",                                         :null => false
    t.datetime "challenge_sent"
    t.integer  "challenge_status",                    :limit => 2
    t.datetime "response_received"
    t.datetime "reply_sent"
    t.integer  "reply_status",                        :limit => 2
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
  end

  add_index "tickets", ["appliance_id"], :name => "index_tickets_on_appliance_id"
  add_index "tickets", ["encrypted_from_number"], :name => "index_tickets_on_encrypted_from_number"
  add_index "tickets", ["encrypted_to_number"], :name => "index_tickets_on_encrypted_to_number"
  add_index "tickets", ["status"], :name => "index_tickets_on_status"

  create_table "transactions", :force => true do |t|
    t.integer  "account_id"
    t.integer  "item_id"
    t.string   "item_type"
    t.string   "narrative",                                                 :null => false
    t.decimal  "value",      :precision => 6, :scale => 4, :default => 0.0
    t.datetime "settled_at"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
  end

  create_table "users", :force => true do |t|
    t.integer  "account_id"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "roles_mask",             :default => 0
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["account_id"], :name => "index_users_on_account_id"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
