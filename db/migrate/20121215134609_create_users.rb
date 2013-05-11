class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :organization
      t.string :first_name
      t.string :last_name
      t.integer :roles_mask, nil: false, default: 0

      t.timestamps
    end
    
    # Add indices
    add_index :users, :organization_id
  end
end
