class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :account_sid, null: false, length: 32
      t.string :auth_token, null: false, length: 32
      t.string :label, null: false
      t.decimal :balance, default: 0, null: false, precision: 8, scale: 4
      t.references :account_plan, null: false
      t.string :purchase_order
      t.string :vat_name
      t.string :vat_number
      t.string :encrypted_twilio_account_sid
      t.string :encrypted_twilio_auth_token
      t.string :twilio_application_sid
      t.string :encrypted_freshbooks_id
      t.integer :primary_address_id
      t.integer :secondary_address_id
      t.text :description

      t.timestamps
    end
    
    # Add indices
    add_index :accounts, :account_sid, unique: true
    add_index :accounts, :label
    add_index :accounts, :encrypted_twilio_account_sid
  end
end
