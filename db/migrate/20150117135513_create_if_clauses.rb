class CreateIfClauses < ActiveRecord::Migration
  def change
    create_table :if_clauses do |t|
      t.string :type
      t.references :parent, index: true, polymorphic: true
      t.integer :order
      t.hstore :settings

      t.timestamps null: false
    end
  end
end
