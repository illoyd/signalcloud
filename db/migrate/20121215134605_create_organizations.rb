class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.references :account_plan, null: false
      
      t.string :workflow_state

      t.string :sid, null: false, length: 32
      t.string :auth_token, null: false, length: 32
      t.string :label, null: false
      t.string :icon
      
      t.references :owner, null: false

      t.integer :contact_address_id
      t.integer :billing_address_id
      
      t.string :purchase_order
      t.string :vat_name
      t.string :vat_number

      t.text :description

      t.timestamps
    end
    
    # Add indices
    add_index :organizations, :sid, unique: true
    add_index :organizations, :label
  end
end
