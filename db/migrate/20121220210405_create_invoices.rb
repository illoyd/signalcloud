class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :account
      t.integer :freshbooks_id
      t.datetime :date_from, null: false
      t.datetime :date_to, null: false

      t.timestamps
    end
    
    # Add indices
    add_index :invoices, :account_id
    add_index :invoices, :freshbooks_id
  end
end
