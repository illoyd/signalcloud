class CreatePhoneBookEntries < ActiveRecord::Migration
  def change
    create_table :phone_book_entries do |t|
      t.references :phone_book, index: true
      t.references :phone_number, index: true
      t.string :country

      t.timestamps null: false
    end
    add_foreign_key :phone_book_entries, :phone_books
    add_foreign_key :phone_book_entries, :phone_numbers
  end
end
