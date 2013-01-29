class CreatePhoneNumbers < ActiveRecord::Migration
  def change
    create_table :phone_numbers do |t|
      t.references :account, null: false
      t.text :encrypted_number, null: false
      t.string :twilio_phone_number_sid, null: false, length: Twilio::SID_LENGTH
      t.integer :unsolicited_sms_action, null: false, limit: 1, default: 3 #PhoneNumber::IGNORE
      t.string :unsolicited_sms_message
      t.integer :unsolicited_call_action, null: false, limit: 1, default: 0 #PhoneNumber::REJECT
      t.string :unsolicited_call_message
      t.string :unsolicited_call_language, default: 'en' #PhoneNumber::AMERICAN_ENGLISH
      t.string :unsolicited_call_voice, default: 'woman' #PhoneNumber::WOMAN_VOICE
      t.decimal :provider_cost, null: false, default: 0, precision: 6, scale: 4
      t.decimal :our_cost, null: false, default: 0, precision: 6, scale: 4

      t.timestamps
    end
    
    # Add indices
    add_index :phone_numbers, :account_id
    add_index :phone_numbers, :encrypted_number
  end
end
