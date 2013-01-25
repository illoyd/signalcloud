class CreateLedgerEntries < ActiveRecord::Migration
  def change
    create_table :ledger_entries do |t|
      t.references :account
      t.references :item, :polymorphic => true
      t.string :narrative, null: false
      t.decimal :value, default: 0, precision: 6, scale: 4
      t.datetime :settled_at

      t.timestamps
    end
  end
end
