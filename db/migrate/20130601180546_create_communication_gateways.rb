class CreateCommunicationGateways < ActiveRecord::Migration
  def change
    create_table :communication_gateways do |t|
      t.string :type
      t.string :workflow_state
      
      t.references :organization

      t.string :encrypted_remote_sid_iv
      t.string :encrypted_remote_sid_salt
      t.text :encrypted_remote_sid
      
      t.string :encrypted_remote_token_iv
      t.string :encrypted_remote_token_salt
      t.text :encrypted_remote_token

      t.string :remote_application
      
      t.datetime :updated_remote_at

      t.timestamps
    end

    # Add indices
    add_index :communication_gateways, :type
    add_index :communication_gateways, :organization_id
    add_index :communication_gateways, [ :organization_id, :type ], unique: true
  end
end
