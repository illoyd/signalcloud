class CreateAccountBalances < ActiveRecord::Migration
  def change
    create_table :account_balances do |t|
      t.references :organization, null: false
      t.decimal :balance, default: 0, null: false, precision: 8, scale: 4

      t.timestamps
    end

    add_index :account_balances, :organization_id, unique: true
  end
end
