class CreateAppliances < ActiveRecord::Migration
  def change
    create_table :appliances do |t|
      t.references :account, null: false
      t.references :phone_directory, null: false
      t.string :label, null: false
      t.integer :seconds_to_live, default: 180, null: false
      t.boolean :primary, default: false, null: false
      t.boolean :active, default: true, null: false
      t.text :description
      t.text :encrypted_question
      t.text :encrypted_expected_confirmed_answer
      t.text :encrypted_expected_denied_answer
      t.text :encrypted_confirmed_reply
      t.text :encrypted_denied_reply
      t.text :encrypted_failed_reply
      t.text :encrypted_expired_reply

      t.timestamps
    end
    
    # Indices
    add_index :appliances, :account_id
    add_index :appliances, :phone_directory_id
    add_index :appliances, :primary
  end
end
