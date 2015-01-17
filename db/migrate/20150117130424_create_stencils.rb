class CreateStencils < ActiveRecord::Migration
  def change
    create_table :stencils do |t|
      t.references :team,       index: true
      t.references :phone_book, index: true

      t.string :workflow_state
      t.string :name,           null: false
      t.text :description

      t.timestamps null: false
    end
    add_index :stencils, :workflow_state
    add_foreign_key :stencils, :teams
    add_foreign_key :stencils, :phone_books
  end
end
