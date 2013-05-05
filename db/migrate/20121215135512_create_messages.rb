class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :conversation, null: false
      t.string :twilio_sid, limit: Twilio::SID_LENGTH
      t.string :message_kind, limit: 1
      t.integer :status, limit: 2, default: 0, null: false
      t.integer :direction, limit: 1, default: 0, null: false
      t.datetime :sent_at
      t.decimal :provider_cost, precision: 6, scale: 4
      t.decimal :our_cost, precision: 6, scale: 4

      t.text :encrypted_to_number
      t.string :encrypted_to_number_iv
      t.string :encrypted_to_number_salt

      t.text :encrypted_from_number
      t.string :encrypted_from_number_iv
      t.string :encrypted_from_number_salt

      t.text :encrypted_body
      t.string :encrypted_body_iv
      t.string :encrypted_body_salt

      t.text :encrypted_provider_response
      t.string :encrypted_provider_response_iv
      t.string :encrypted_provider_response_salt

      t.text :encrypted_provider_update
      t.string :encrypted_provider_update_iv
      t.string :encrypted_provider_update_salt

      t.timestamps
    end
    
    # Indices
    add_index :messages, :conversation_id
    add_index :messages, :updated_at
    add_index :messages, :message_kind
    add_index :messages, :status
  end
end
