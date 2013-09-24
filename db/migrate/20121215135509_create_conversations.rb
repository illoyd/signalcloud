class CreateConversations < ActiveRecord::Migration
  def change
    #create_table :conversations, primary_key: :id do |t|
    #  t.column :id, :bigint, null: false
    create_table :conversations do |t|
      t.references :stencil, null: false

      t.integer :status, null: false, default: 0, limit: 2
      t.integer :challenge_status, limit: 2
      t.integer :reply_status, limit: 2
      
      t.string :hashed_internal_number, null: false
      t.string :hashed_customer_number, null: false

      t.datetime :expires_at, null: false
      t.datetime :challenge_sent_at, null: true
      t.datetime :response_received_at, null: true
      t.datetime :reply_sent_at, null: true
      

      t.text :encrypted_from_number, null: false
      t.string :encrypted_from_number_iv
      t.string :encrypted_from_number_salt

      t.text :encrypted_to_number, null: false
      t.string :encrypted_to_number_iv
      t.string :encrypted_to_number_salt

      t.text :encrypted_expected_confirmed_answer, null: false
      t.string :encrypted_expected_confirmed_answer_iv
      t.string :encrypted_expected_confirmed_answer_salt

      t.text :encrypted_expected_denied_answer, null: false
      t.string :encrypted_expected_denied_answer_iv
      t.string :encrypted_expected_denied_answer_salt

      t.text :encrypted_question, null: false
      t.string :encrypted_question_iv
      t.string :encrypted_question_salt

      t.text :encrypted_confirmed_reply, null: false
      t.string :encrypted_confirmed_reply_iv
      t.string :encrypted_confirmed_reply_salt

      t.text :encrypted_denied_reply, null: false
      t.string :encrypted_denied_reply_iv
      t.string :encrypted_denied_reply_salt

      t.text :encrypted_failed_reply, null: false
      t.string :encrypted_failed_reply_iv
      t.string :encrypted_failed_reply_salt

      t.text :encrypted_expired_reply, null: false
      t.string :encrypted_expired_reply_iv
      t.string :encrypted_expired_reply_salt
      
      t.text :encrypted_webhook_uri
      t.string :encrypted_webhook_uri_iv
      t.string :encrypted_webhook_uri_salt

      t.timestamps
    end
    
    # Add indexes
    add_index :conversations, :stencil_id
    add_index :conversations, :status
    add_index :conversations, :hashed_internal_number
    add_index :conversations, :hashed_customer_number
    
  end
end
