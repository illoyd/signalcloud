class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.references :organization
      t.references :user
      
      t.integer :roles_mask, null: false, default: 0

      t.timestamps
    end
    
    # Add indices
    add_index :user_roles, :organization_id
    add_index :user_roles, :user_id
  end
end
