class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :workflow_state
      
      # References
      t.references :conversation, null: false

      # Communication gateway information
      t.references :communication_gateway, null: false
      t.string :provider_sid, limit: Twilio::SID_LENGTH

      # General details
      t.string :message_kind, limit: 9
      t.string :direction, limit: 3
      t.datetime :sent_at
      
      # Cost details
      t.decimal :provider_cost, precision: 6, scale: 4
      t.decimal :our_cost, precision: 6, scale: 4

      # Error field
      t.string :error_code
      
      # Encrypted data
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
    add_index :messages, :workflow_state
    add_index :messages, [ :communication_gateway_id, :provider_sid ], unique: true
  end
end
