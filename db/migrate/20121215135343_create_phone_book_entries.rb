class CreatePhoneBookEntries < ActiveRecord::Migration
  def change
    create_table :phone_book_entries do |t|
      t.references :phone_book, null: false
      t.references :phone_number, null: false
      t.string :country

      t.timestamps
    end
    
    # More indices
    add_index :phone_book_entries, :phone_book_id
    add_index :phone_book_entries, :phone_number_id
    add_index :phone_book_entries, :country
  end
end
