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

ActiveRecord::Schema.define(version: 20140824211623) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_balances", force: true do |t|
    t.integer  "organization_id",                                       null: false
    t.decimal  "balance",         precision: 8, scale: 4, default: 0.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_balances", ["organization_id"], name: "index_account_balances_on_organization_id", unique: true, using: :btree

  create_table "account_plans", force: true do |t|
    t.string   "label",        limit: 255,                                         null: false
    t.boolean  "default",                                          default: false, null: false
    t.integer  "plan_kind",    limit: 2,                           default: 0,     null: false
    t.decimal  "month",                    precision: 8, scale: 4, default: 0.0,   null: false
    t.decimal  "phone_add",                precision: 6, scale: 4, default: 0.0,   null: false
    t.decimal  "phone_mult",               precision: 6, scale: 4, default: 0.0,   null: false
    t.decimal  "call_in_add",              precision: 6, scale: 4, default: 0.0,   null: false
    t.decimal  "call_in_mult",             precision: 6, scale: 4, default: 0.0,   null: false
    t.decimal  "sms_in_add",               precision: 6, scale: 4, default: 0.0,   null: false
    t.decimal  "sms_in_mult",              precision: 6, scale: 4, default: 0.0,   null: false
    t.decimal  "sms_out_add",              precision: 6, scale: 4, default: 0.0,   null: false
    t.decimal  "sms_out_mult",             precision: 6, scale: 4, default: 0.0,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounting_gateways", force: true do |t|
    t.string   "workflow_state",            limit: 255
    t.string   "type",                      limit: 255
    t.integer  "organization_id"
    t.string   "encrypted_remote_sid_iv",   limit: 255
    t.string   "encrypted_remote_sid_salt", limit: 255
    t.text     "encrypted_remote_sid"
    t.datetime "updated_remote_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "boxes", force: true do |t|
    t.string   "workflow_state",  limit: 255
    t.integer  "organization_id",             null: false
    t.datetime "start_at"
    t.string   "label",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communication_gateways", force: true do |t|
    t.string   "type",                        limit: 255
    t.string   "workflow_state",              limit: 255
    t.integer  "organization_id"
    t.string   "encrypted_remote_sid_iv",     limit: 255
    t.string   "encrypted_remote_sid_salt",   limit: 255
    t.text     "encrypted_remote_sid"
    t.string   "encrypted_remote_token_iv",   limit: 255
    t.string   "encrypted_remote_token_salt", limit: 255
    t.text     "encrypted_remote_token"
    t.string   "remote_application",          limit: 255
    t.datetime "updated_remote_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "communication_gateways", ["organization_id", "type"], name: "index_communication_gateways_on_organization_id_and_type", unique: true, using: :btree
  add_index "communication_gateways", ["organization_id"], name: "index_communication_gateways_on_organization_id", using: :btree
  add_index "communication_gateways", ["type"], name: "index_communication_gateways_on_type", using: :btree

  create_table "conversations", force: true do |t|
    t.string   "workflow_state",                           limit: 255
    t.integer  "stencil_id",                                                           null: false
    t.integer  "box_id"
    t.string   "hashed_internal_number",                   limit: 255,                 null: false
    t.string   "hashed_customer_number",                   limit: 255,                 null: false
    t.boolean  "mock",                                                 default: false
    t.datetime "send_at"
    t.datetime "expires_at",                                                           null: false
    t.datetime "challenge_sent_at"
    t.datetime "response_received_at"
    t.datetime "reply_sent_at"
    t.string   "challenge_status",                         limit: 255
    t.string   "reply_status",                             limit: 255
    t.string   "error_code",                               limit: 255
    t.text     "encrypted_old_internal_number"
    t.string   "encrypted_old_internal_number_iv",         limit: 255
    t.string   "encrypted_old_internal_number_salt",       limit: 255
    t.text     "encrypted_customer_number",                                            null: false
    t.string   "encrypted_customer_number_iv",             limit: 255
    t.string   "encrypted_customer_number_salt",           limit: 255
    t.text     "encrypted_expected_confirmed_answer",                                  null: false
    t.string   "encrypted_expected_confirmed_answer_iv",   limit: 255
    t.string   "encrypted_expected_confirmed_answer_salt", limit: 255
    t.text     "encrypted_expected_denied_answer",                                     null: false
    t.string   "encrypted_expected_denied_answer_iv",      limit: 255
    t.string   "encrypted_expected_denied_answer_salt",    limit: 255
    t.text     "encrypted_question",                                                   null: false
    t.string   "encrypted_question_iv",                    limit: 255
    t.string   "encrypted_question_salt",                  limit: 255
    t.text     "encrypted_confirmed_reply",                                            null: false
    t.string   "encrypted_confirmed_reply_iv",             limit: 255
    t.string   "encrypted_confirmed_reply_salt",           limit: 255
    t.text     "encrypted_denied_reply",                                               null: false
    t.string   "encrypted_denied_reply_iv",                limit: 255
    t.string   "encrypted_denied_reply_salt",              limit: 255
    t.text     "encrypted_failed_reply",                                               null: false
    t.string   "encrypted_failed_reply_iv",                limit: 255
    t.string   "encrypted_failed_reply_salt",              limit: 255
    t.text     "encrypted_expired_reply",                                              null: false
    t.string   "encrypted_expired_reply_iv",               limit: 255
    t.string   "encrypted_expired_reply_salt",             limit: 255
    t.text     "encrypted_webhook_uri"
    t.string   "encrypted_webhook_uri_iv",                 limit: 255
    t.string   "encrypted_webhook_uri_salt",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "internal_number_id"
  end

  add_index "conversations", ["hashed_customer_number"], name: "index_conversations_on_hashed_customer_number", using: :btree
  add_index "conversations", ["hashed_internal_number"], name: "index_conversations_on_hashed_internal_number", using: :btree
  add_index "conversations", ["internal_number_id"], name: "index_conversations_on_internal_number_id", using: :btree
  add_index "conversations", ["stencil_id"], name: "index_conversations_on_stencil_id", using: :btree
  add_index "conversations", ["workflow_state"], name: "index_conversations_on_workflow_state", using: :btree

  create_table "invoices", force: true do |t|
    t.integer  "organization_id"
    t.integer  "freshbooks_invoice_id"
    t.string   "workflow_state",        limit: 255
    t.string   "purchase_order",        limit: 255
    t.string   "public_link",           limit: 255
    t.string   "internal_link",         limit: 255
    t.datetime "date_from",                         null: false
    t.datetime "date_to",                           null: false
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices", ["freshbooks_invoice_id"], name: "index_invoices_on_freshbooks_invoice_id", using: :btree
  add_index "invoices", ["organization_id"], name: "index_invoices_on_organization_id", using: :btree

  create_table "ledger_entries", force: true do |t|
    t.integer  "organization_id"
    t.integer  "invoice_id"
    t.integer  "item_id"
    t.string   "item_type",       limit: 255
    t.string   "narrative",       limit: 255,                                       null: false
    t.decimal  "value",                       precision: 8, scale: 4, default: 0.0
    t.datetime "settled_at"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: true do |t|
    t.string   "workflow_state",                   limit: 255
    t.integer  "conversation_id",                                                                  null: false
    t.string   "provider_sid",                     limit: 34
    t.string   "message_kind",                     limit: 9
    t.string   "direction",                        limit: 3
    t.integer  "segments",                                                             default: 1, null: false
    t.datetime "sent_at"
    t.decimal  "cost",                                         precision: 9, scale: 6
    t.string   "error_code",                       limit: 255
    t.text     "encrypted_to_number"
    t.string   "encrypted_to_number_iv",           limit: 255
    t.string   "encrypted_to_number_salt",         limit: 255
    t.text     "encrypted_from_number"
    t.string   "encrypted_from_number_iv",         limit: 255
    t.string   "encrypted_from_number_salt",       limit: 255
    t.text     "encrypted_body"
    t.string   "encrypted_body_iv",                limit: 255
    t.string   "encrypted_body_salt",              limit: 255
    t.text     "encrypted_provider_response"
    t.string   "encrypted_provider_response_iv",   limit: 255
    t.string   "encrypted_provider_response_salt", limit: 255
    t.text     "encrypted_provider_update"
    t.string   "encrypted_provider_update_iv",     limit: 255
    t.string   "encrypted_provider_update_salt",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["conversation_id"], name: "index_messages_on_conversation_id", using: :btree
  add_index "messages", ["message_kind"], name: "index_messages_on_message_kind", using: :btree
  add_index "messages", ["updated_at"], name: "index_messages_on_updated_at", using: :btree
  add_index "messages", ["workflow_state"], name: "index_messages_on_workflow_state", using: :btree

  create_table "organizations", force: true do |t|
    t.integer  "account_plan_id",                                           null: false
    t.string   "workflow_state",                 limit: 255
    t.string   "sid",                            limit: 255,                null: false
    t.string   "auth_token",                     limit: 255,                null: false
    t.string   "label",                          limit: 255,                null: false
    t.string   "icon",                           limit: 255
    t.integer  "owner_id",                                                  null: false
    t.string   "purchase_order",                 limit: 255
    t.string   "vat_name",                       limit: 255
    t.string   "vat_number",                     limit: 255
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "billing_first_name",             limit: 255
    t.string   "billing_last_name",              limit: 255
    t.string   "billing_email",                  limit: 255
    t.string   "billing_line1",                  limit: 255
    t.string   "billing_line2",                  limit: 255
    t.string   "billing_city",                   limit: 255
    t.string   "billing_region",                 limit: 255
    t.string   "billing_postcode",               limit: 255
    t.string   "billing_country",                limit: 255
    t.string   "billing_work_phone",             limit: 255
    t.string   "contact_first_name",             limit: 255
    t.string   "contact_last_name",              limit: 255
    t.string   "contact_email",                  limit: 255
    t.string   "contact_line1",                  limit: 255
    t.string   "contact_line2",                  limit: 255
    t.string   "contact_city",                   limit: 255
    t.string   "contact_region",                 limit: 255
    t.string   "contact_postcode",               limit: 255
    t.string   "contact_country",                limit: 255
    t.string   "contact_work_phone",             limit: 255
    t.boolean  "use_billing_as_contact_address",             default: true, null: false
  end

  add_index "organizations", ["label"], name: "index_organizations_on_label", using: :btree
  add_index "organizations", ["sid"], name: "index_organizations_on_sid", unique: true, using: :btree

  create_table "payment_gateways", force: true do |t|
    t.string   "workflow_state",            limit: 255
    t.string   "type",                      limit: 255
    t.integer  "organization_id"
    t.string   "encrypted_remote_sid_iv",   limit: 255
    t.string   "encrypted_remote_sid_salt", limit: 255
    t.text     "encrypted_remote_sid"
    t.datetime "updated_remote_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phone_book_entries", force: true do |t|
    t.integer  "phone_book_id",               null: false
    t.integer  "phone_number_id",             null: false
    t.string   "country",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "phone_book_entries", ["country"], name: "index_phone_book_entries_on_country", using: :btree
  add_index "phone_book_entries", ["phone_book_id"], name: "index_phone_book_entries_on_phone_book_id", using: :btree
  add_index "phone_book_entries", ["phone_number_id"], name: "index_phone_book_entries_on_phone_number_id", using: :btree

  create_table "phone_books", force: true do |t|
    t.integer  "organization_id",             null: false
    t.string   "label",           limit: 255, null: false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "phone_books", ["organization_id"], name: "index_phone_books_on_organization_id", using: :btree

  create_table "phone_numbers", force: true do |t|
    t.integer  "organization_id",                                                                 null: false
    t.string   "number",                    limit: 255,                                           null: false
    t.string   "workflow_state",            limit: 255
    t.integer  "communication_gateway_id",                                                        null: false
    t.string   "provider_sid",              limit: 255
    t.integer  "unsolicited_sms_action",    limit: 2,                           default: 0,       null: false
    t.string   "unsolicited_sms_message",   limit: 255
    t.integer  "unsolicited_call_action",   limit: 2,                           default: 0,       null: false
    t.string   "unsolicited_call_message",  limit: 255
    t.string   "unsolicited_call_language", limit: 255,                         default: "en"
    t.string   "unsolicited_call_voice",    limit: 255,                         default: "woman"
    t.decimal  "cost",                                  precision: 9, scale: 6, default: 0.0,     null: false
    t.datetime "updated_remote_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "phone_numbers", ["number"], name: "index_phone_numbers_on_number", using: :btree
  add_index "phone_numbers", ["organization_id"], name: "index_phone_numbers_on_organization_id", using: :btree

  create_table "stencils", force: true do |t|
    t.integer  "organization_id",                                                      null: false
    t.integer  "phone_book_id",                                                        null: false
    t.string   "label",                                    limit: 255,                 null: false
    t.integer  "seconds_to_live",                                      default: 180,   null: false
    t.boolean  "primary",                                              default: false, null: false
    t.boolean  "active",                                               default: true,  null: false
    t.text     "description"
    t.text     "encrypted_question"
    t.string   "encrypted_question_iv",                    limit: 255
    t.string   "encrypted_question_salt",                  limit: 255
    t.text     "encrypted_expected_confirmed_answer"
    t.string   "encrypted_expected_confirmed_answer_iv",   limit: 255
    t.string   "encrypted_expected_confirmed_answer_salt", limit: 255
    t.text     "encrypted_expected_denied_answer"
    t.string   "encrypted_expected_denied_answer_iv",      limit: 255
    t.string   "encrypted_expected_denied_answer_salt",    limit: 255
    t.text     "encrypted_confirmed_reply"
    t.string   "encrypted_confirmed_reply_iv",             limit: 255
    t.string   "encrypted_confirmed_reply_salt",           limit: 255
    t.text     "encrypted_denied_reply"
    t.string   "encrypted_denied_reply_iv",                limit: 255
    t.string   "encrypted_denied_reply_salt",              limit: 255
    t.text     "encrypted_failed_reply"
    t.string   "encrypted_failed_reply_iv",                limit: 255
    t.string   "encrypted_failed_reply_salt",              limit: 255
    t.text     "encrypted_expired_reply"
    t.string   "encrypted_expired_reply_iv",               limit: 255
    t.string   "encrypted_expired_reply_salt",             limit: 255
    t.text     "encrypted_webhook_uri"
    t.string   "encrypted_webhook_uri_iv",                 limit: 255
    t.string   "encrypted_webhook_uri_salt",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stencils", ["organization_id"], name: "index_stencils_on_organization_id", using: :btree
  add_index "stencils", ["phone_book_id"], name: "index_stencils_on_phone_book_id", using: :btree
  add_index "stencils", ["primary"], name: "index_stencils_on_primary", using: :btree

  create_table "unsolicited_calls", force: true do |t|
    t.integer  "phone_number_id"
    t.string   "provider_sid",    limit: 34,                                      null: false
    t.string   "customer_number", limit: 255,                                     null: false
    t.datetime "received_at",                                                     null: false
    t.integer  "action_taken",                                        default: 0, null: false
    t.datetime "action_taken_at"
    t.decimal  "provider_price",              precision: 6, scale: 4
    t.decimal  "our_price",                   precision: 6, scale: 4
    t.text     "call_content",                                                    null: false
    t.text     "action_content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unsolicited_calls", ["phone_number_id"], name: "index_unsolicited_calls_on_phone_number_id", using: :btree

  create_table "unsolicited_messages", force: true do |t|
    t.integer  "phone_number_id"
    t.string   "provider_sid",    limit: 34,                                      null: false
    t.string   "customer_number", limit: 255,                                     null: false
    t.datetime "received_at",                                                     null: false
    t.integer  "action_taken",                                        default: 0, null: false
    t.datetime "action_taken_at"
    t.decimal  "provider_price",              precision: 6, scale: 4
    t.decimal  "our_price",                   precision: 6, scale: 4
    t.text     "message_content",                                                 null: false
    t.text     "action_content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unsolicited_messages", ["phone_number_id"], name: "index_unsolicited_messages_on_phone_number_id", using: :btree

  create_table "user_roles", force: true do |t|
    t.integer  "organization_id"
    t.integer  "user_id"
    t.integer  "roles_mask",      default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_roles", ["organization_id"], name: "index_user_roles_on_organization_id", using: :btree
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "name",                   limit: 255
    t.string   "nickname",               limit: 255
    t.boolean  "system_admin",                       default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: ""
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "failed_attempts",                    default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.string   "authentication_token",   limit: 255
    t.string   "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type",        limit: 255
    t.datetime "invitation_created_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

end
