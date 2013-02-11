class CreateLedgerEntries < ActiveRecord::Migration
  def change
    create_table :ledger_entries do |t|
      t.references :account
      t.references :item, :polymorphic => true
      t.string :narrative, null: false
      t.decimal :value, precision: 8, scale: 4, default: 0.0, null: false
      t.datetime :settled_at
      t.text :notes

      t.timestamps
    end
  end
end
