class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.references :account
      t.string :line1
      t.string :line2
      t.string :city, null: false
      t.string :region
      t.string :postcode
      t.string :country, null: false

      t.timestamps
    end
    
    # Add indices
    add_index :addresses, :account_id
    add_index :addresses, :country
  end
end
