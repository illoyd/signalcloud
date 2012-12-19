class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :account
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
    
    # Add indices
    add_index :users, :account_id
  end
end
