class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.references :organization
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :line1
      t.string :line2
      t.string :city
      t.string :region
      t.string :postcode
      t.string :country
      t.string :work_phone

      t.timestamps
    end
    
    # Add indices
    add_index :addresses, :organization_id
    add_index :addresses, :country
  end
end
