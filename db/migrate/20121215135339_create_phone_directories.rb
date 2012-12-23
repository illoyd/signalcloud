class CreatePhoneDirectories < ActiveRecord::Migration
  def change
    create_table :phone_directories do |t|
      t.references :account, null: false
      t.string :label, null: false
      t.text :description

      t.timestamps
    end
    
    # Add indices
    add_index :phone_directories, :account_id
  end
end
