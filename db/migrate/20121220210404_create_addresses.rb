class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.references :organization
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :line1
      t.string :line2
      t.string :city, null: false
      t.string :region
      t.string :postcode
      t.string :country, null: false
      t.string :work_phone

      t.timestamps
    end
    
    # Add indices
    add_index :addresses, :organization_id
    add_index :addresses, :country
  end
end
