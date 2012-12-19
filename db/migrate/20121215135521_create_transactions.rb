class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :narrative, null: false
      t.decimal :value, null: false, default: 0, precision: 6, scale: 4
      t.references :item, :polymorphic => true

      t.timestamps
    end
  end
end
