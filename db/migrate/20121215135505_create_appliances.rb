class CreateAppliances < ActiveRecord::Migration
  def change
    create_table :appliances do |t|
      t.references :account, null: false
      t.references :phone_directory, null: false
      t.integer :seconds_to_live, default: 180, null: false
      t.boolean :default, default: false, null: false
      t.string :encrypted_question, null: false
      t.string :encrypted_expected_confirmed_answer, null: false
      t.string :encrypted_expected_denied_answer, null: false
      t.string :encrypted_confirmed_reply, null: false
      t.string :encrypted_denied_reply, null: false
      t.string :encrypted_failed_reply, null: false
      t.string :encrypted_expired_reply, null: false

      t.timestamps
    end
    
    # Indices
    add_index :appliances, :account_id
    add_index :appliances, :default
    add_index :appliances, :phone_directory_id
  end
end
