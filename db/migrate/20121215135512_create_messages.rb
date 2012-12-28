class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :ticket, null: false
      t.string :twilio_sid, null: false, limit: 34
      t.decimal :provider_cost, null: false, default: 0, precision: 6, scale: 4
      t.decimal :our_cost, null: false, default: 0, precision: 6, scale: 4
      t.text :text, null: false
      t.text :encrypted_payload, null: false

      t.timestamps
    end
    
    # Indices
    add_index :messages, :ticket_id, :updated_at
  end
end
