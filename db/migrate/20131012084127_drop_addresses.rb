class DropAddresses < ActiveRecord::Migration
  def up
    remove_column :organizations, :contact_address_id
    remove_column :organizations, :billing_address_id
    drop_table :addresses
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
