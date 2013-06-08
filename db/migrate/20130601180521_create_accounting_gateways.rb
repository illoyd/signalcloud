class CreateAccountingGateways < ActiveRecord::Migration
  def change
    create_table :accounting_gateways do |t|
      t.string :workflow_state
      t.string :type

      t.references :organization
      
      t.string :encrypted_remote_sid_iv
      t.string :encrypted_remote_sid_salt
      t.text :encrypted_remote_sid

      t.datetime :updated_remote_at

      t.timestamps
    end
  end
end
