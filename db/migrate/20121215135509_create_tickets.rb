class CreateTickets < ActiveRecord::Migration
  def change
    #create_table :tickets, primary_key: :id do |t|
    #  t.column :id, :bigint, null: false
    create_table :tickets do |t|
      #t.column :id, :bigint, null: false
      t.references :appliance, null: false
      t.integer :status, null: false, default: 0, limit: 4
      t.string :encrypted_from_number, null: false
      t.string :encrypted_to_number, null: false
      t.datetime :expiry, null: false
      t.string :encrypted_question, null: false
      t.string :encrypted_expected_confirmed_answer, null: false
      t.string :encrypted_expected_denied_answer, null: false
      t.string :encrypted_actual_answer
      t.string :encrypted_confirmed_reply, null: false
      t.string :encrypted_denied_reply, null: false
      t.string :encrypted_failed_reply, null: false
      t.string :encrypted_expired_reply, null: false
      t.datetime :challenge_sent
      t.integer :challenge_status
      t.datetime :response_received
      t.datetime :reply_sent
      t.integer :reply_status

      t.timestamps
    end
    
    # Add indexes
    add_index :tickets, :appliance_id
    add_index :tickets, :status
    add_index :tickets, :encrypted_from_number
    add_index :tickets, :encrypted_to_number
    
  end
end
