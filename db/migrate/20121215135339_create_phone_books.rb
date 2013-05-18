class CreatePhoneBooks < ActiveRecord::Migration
  def change
    create_table :phone_books do |t|
      t.references :organization, null: false
      t.string :label, null: false
      t.text :description

      t.timestamps
    end
    
    # Add indices
    add_index :phone_books, :organization_id
  end
end
