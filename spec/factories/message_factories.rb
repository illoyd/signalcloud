FactoryGirl.define do

  factory :message do
    status        Message::SENT
    provider_cost { random_price() }
    our_cost      { random_price() }
    twilio_sid    { 'SM' + SecureRandom.hex(16) }
    
    after(:create) do |message, evaluator|
      FactoryGirl.create(:ledger_entry, account: message.ticket.appliance.account, item: message, value: message.provider_cost + message.our_cost, narrative: LedgerEntry::OUTBOUND_SMS_NARRATIVE )
    end

    factory :challenge_message do
      message_kind  Message::CHALLENGE
    end

    factory :reply_message do
      message_kind  Message::REPLY
    end
  end

end
