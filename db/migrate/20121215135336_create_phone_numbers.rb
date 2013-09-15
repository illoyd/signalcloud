class CreatePhoneNumbers < ActiveRecord::Migration
  def change
    create_table :phone_numbers do |t|
      t.references :organization, null: false

      t.string :number, null: false
      
      t.string :workflow_state

      t.string :twilio_phone_number_sid, length: Twilio::SID_LENGTH

      t.integer :unsolicited_sms_action, null: false, limit: 1, default: PhoneNumber::IGNORE
      t.string :unsolicited_sms_message

      t.integer :unsolicited_call_action, null: false, limit: 1, default: PhoneNumber::REJECT
      t.string :unsolicited_call_message
      t.string :unsolicited_call_language, default: PhoneNumber::AMERICAN_ENGLISH
      t.string :unsolicited_call_voice, default: PhoneNumber::WOMAN_VOICE

      t.decimal :provider_cost, null: false, default: 0, precision: 6, scale: 4
      t.decimal :our_cost, null: false, default: 0, precision: 6, scale: 4

      t.timestamps
    end
    
    # Add indices
    add_index :phone_numbers, :organization_id
    add_index :phone_numbers, :number
  end
end
