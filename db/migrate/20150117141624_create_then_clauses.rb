class CreateThenClauses < ActiveRecord::Migration
  def change
    create_table :then_clauses do |t|
      t.references :if_clause, index: true
      t.string :type
      t.integer :order
      t.hstore :settings

      t.timestamps null: false
    end
    add_foreign_key :then_clauses, :if_clauses
  end
end
