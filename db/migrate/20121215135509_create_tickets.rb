class CreateTickets < ActiveRecord::Migration
  def change
    #create_table :tickets, primary_key: :id do |t|
    #  t.column :id, :bigint, null: false
    create_table :tickets do |t|
      #t.column :id, :bigint, null: false
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
      
      t.string :webhook_uri

      t.text :encrypted_from_number, null: false
      t.string :encrypted_from_number_iv
      t.string :encrypted_from_number_salt

      t.text :encrypted_to_number, null: false
      t.string :encrypted_to_number_iv
      t.string :encrypted_to_number_salt

      t.text :hashed_expected_confirmed_answer, null: false
      t.text :hashed_expected_denied_answer, null: false

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

      t.timestamps
    end
    
    # Add indexes
    add_index :tickets, :stencil_id
    add_index :tickets, :status
    add_index :tickets, :hashed_internal_number
    add_index :tickets, :hashed_customer_number
    
  end
end
