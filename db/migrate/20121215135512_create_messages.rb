class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :ticket, null: false
      t.string :twilio_sid, limit: Twilio::SID_LENGTH
      t.string :message_kind, limit: 1
      t.integer :status, limit: 2, default: 0, null: false
      t.datetime :sent_at
      t.decimal :provider_cost, precision: 6, scale: 4
      t.decimal :our_cost, precision: 6, scale: 4
      t.text :encrypted_payload
      t.text :encrypted_callback_payload

      t.timestamps
    end
    
    # Indices
    add_index :messages, :ticket_id
    add_index :messages, :updated_at
    add_index :messages, :message_kind
    add_index :messages, :status
  end
end
