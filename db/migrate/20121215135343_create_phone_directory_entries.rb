class CreatePhoneDirectoryEntries < ActiveRecord::Migration
  def change
    create_table :phone_directory_entries do |t|
      t.references :phone_directory, null: false
      t.references :phone_number, null: false
      t.string :country

      t.timestamps
    end
    
    # More indices
    add_index :phone_directory_entries, :phone_directory_id
    add_index :phone_directory_entries, :phone_number_id
    add_index :phone_directory_entries, :country
  end
end
