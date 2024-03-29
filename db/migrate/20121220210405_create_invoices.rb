class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :organization
      t.integer :freshbooks_invoice_id
      t.string :workflow_state
      t.string :purchase_order
      t.string :public_link
      t.string :internal_link
      t.datetime :date_from, null: false
      t.datetime :date_to, null: false
      t.datetime :sent_at

      t.timestamps
    end
    
    # Add indices
    add_index :invoices, :organization_id
    add_index :invoices, :freshbooks_invoice_id
  end
end
