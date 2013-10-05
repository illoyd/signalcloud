class CreateUnsolicitedMessages < ActiveRecord::Migration
  def change
    create_table :unsolicited_messages do |t|
      t.references :phone_number
      t.string :provider_sid, null: false, limit: Twilio::SID_LENGTH
      t.string :customer_number, null: false
      t.datetime :received_at, null: false
      t.integer :action_taken, null: false, default: PhoneNumber::IGNORE
      t.datetime :action_taken_at
      t.decimal :provider_price, precision: 6, scale: 4
      t.decimal :our_price, precision: 6, scale: 4
      t.text :message_content, null: false
      t.text :action_content

      t.timestamps
    end
    add_index :unsolicited_messages, :phone_number_id
  end
end
