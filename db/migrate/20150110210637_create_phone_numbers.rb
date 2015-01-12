class CreatePhoneNumbers < ActiveRecord::Migration
  def change
    create_table :phone_numbers do |t|
      t.string :type
      t.references :team,      null: false, index: true
      t.string :workflow_state
      t.string :number,        null: false
      t.string :provider_sid
      
      t.text :description

      t.timestamps null: false
    end
    add_index :phone_numbers, :type
    add_index :phone_numbers, :workflow_state
    add_index :phone_numbers, :number
    add_foreign_key :phone_numbers, :teams
  end
end
