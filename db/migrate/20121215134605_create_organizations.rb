class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.references :account_plan, null: false
      t.string :sid, null: false, length: 32
      t.string :auth_token, null: false, length: 32
      t.string :label, null: false
      t.decimal :balance, default: 0, null: false, precision: 8, scale: 4

      t.integer :primary_address_id
      t.integer :secondary_address_id
      
      t.string :purchase_order
      t.string :vat_name
      t.string :vat_number

      t.text :encrypted_twilio_account_sid
      t.string :encrypted_twilio_account_sid_iv
      t.string :encrypted_twilio_account_sid_salt
      
      t.text :encrypted_twilio_auth_token
      t.string :encrypted_twilio_auth_token_iv
      t.string :encrypted_twilio_auth_token_salt

      t.string :twilio_application_sid

      t.text :encrypted_freshbooks_id
      t.string :encrypted_freshbooks_id_iv
      t.string :encrypted_freshbooks_id_salt

      t.text :encrypted_braintree_id
      t.string :encrypted_braintree_id_iv
      t.string :encrypted_braintree_id_salt

      t.text :description

      t.timestamps
    end
    
    # Add indices
    add_index :organizations, :sid, unique: true
    add_index :organizations, :label
    add_index :organizations, :encrypted_twilio_account_sid
  end
end
