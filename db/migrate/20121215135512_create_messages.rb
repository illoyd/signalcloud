class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :ticket, null: false
      t.string :twilio_sid, limit: Twilio::SID_LENGTH
      t.decimal :provider_cost, null: false, default: 0, precision: 6, scale: 4
      t.decimal :our_cost, null: false, default: 0, precision: 6, scale: 4
      t.text :encrypted_payload
      t.text :encrypted_callback_payload

      t.timestamps
    end
    
    # Indices
    add_index :messages, :ticket_id
    add_index :messages, :updated_at
  end
end
