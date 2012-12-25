class CreatePhoneNumbers < ActiveRecord::Migration
  def change
    create_table :phone_numbers do |t|
      t.references :account, null: false
      t.string :encrypted_number, null: false
      t.string :twilio_phone_number_sid, null: false, length: 34
      t.decimal :provider_cost, null: false, default: 0, precision: 6, scale: 4
      t.decimal :our_cost, null: false, default: 0, precision: 6, scale: 4

      t.timestamps
    end
    
    # Add indices
    add_index :phone_numbers, :account_id
    add_index :phone_numbers, :encrypted_number
  end
end
