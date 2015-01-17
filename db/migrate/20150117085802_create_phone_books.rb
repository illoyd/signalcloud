class CreatePhoneBooks < ActiveRecord::Migration
  def change
    create_table :phone_books do |t|
      t.references :team, index: true
      t.string :workflow_state
      t.string :name
      t.text :description

      t.timestamps null: false
    end
    add_index :phone_books, :workflow_state
    add_foreign_key :phone_books, :teams
  end
end
