class CreateConversations < ActiveRecord::Migration
  def change
    #create_table :conversations, primary_key: :id do |t|
    #  t.column :id, :bigint, null: false
    create_table :conversations do |t|
      t.string :workflow_state

      # References
      t.references :stencil, null: false
      t.references :box, null: true

      # Fast search utilities
      t.string :hashed_internal_number, null: false
      t.string :hashed_customer_number, null: false
      
      # Mock this conversation?
      t.boolean :mock, default: false

      # Time information
      t.datetime :send_at, null: true
      t.datetime :expires_at, null: false
      t.datetime :challenge_sent_at, null: true
      t.datetime :response_received_at, null: true
      t.datetime :reply_sent_at, null: true
      
      # Additional state information
      t.string :challenge_status
      t.string :reply_status
      
      # Error field
      t.string :error_code
      
      # Encrypted data
      t.text :encrypted_internal_number, null: false
      t.string :encrypted_internal_number_iv
      t.string :encrypted_internal_number_salt

      t.text :encrypted_customer_number, null: false
      t.string :encrypted_customer_number_iv
      t.string :encrypted_customer_number_salt

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
      
      t.text :encrypted_parameters
      t.string :encrypted_parameters_iv
      t.string :encrypted_parameters_salt
      
      t.text :encrypted_webhook_uri
      t.string :encrypted_webhook_uri_iv
      t.string :encrypted_webhook_uri_salt

      t.timestamps
    end
    
    # Add indexes
    add_index :conversations, :stencil_id
    add_index :conversations, :workflow_state
    add_index :conversations, :hashed_internal_number
    add_index :conversations, :hashed_customer_number
    
  end
end
