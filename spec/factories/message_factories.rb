FactoryGirl.define do

  factory :message do
    ticket
    status        Message::PENDING
    
    after(:create) do |message, evaluator|
      FactoryGirl.create(:ledger_entry, account: message.ticket.stencil.account, item: message, value: message.cost, narrative: LedgerEntry::OUTBOUND_SMS_NARRATIVE )
    end
    
    trait :with_costs do
      provider_cost    { random_cost() }
      our_cost         { random_cost() }
    end
    
    trait :with_twilio_sid do
      twilio_sid        'SMe7a99c10b98ee37aa680ee0617c76d21'
    end
    
    trait :with_random_twilio_sid do
      twilio_sid        { 'SM' + SecureRandom.hex(16) }
    end
    
    trait :with_provider_response do
      provider_response { {
                          "sid" => twilio_sid,
                          "date_created" => DateTime.now,
                          "date_updated" => DateTime.now,
                          "date_sent" => nil,
                          "account_sid" => ticket.stencil.account.twilio_account_sid,
                          "to" => ticket.to_number,
                          "from" => ticket.from_number,
                          "body" => ticket.question,
                          "status" => "queued",
                          "direction" => "outbound-api",
                          "api_version" => "2010-04-01",
                          "price" => nil,
                          "uri" => "\/2010-04-01\/Accounts\/#{ticket.stencil.account.twilio_account_sid}\/SMS\/Messages\/#{twilio_sid}.json"
                        } }
    end

    factory :challenge_message do
      challenge
    end

    factory :reply_message do
      reply
    end

    trait :challenge do
      message_kind  Message::CHALLENGE
    end

    trait :reply do
      message_kind  Message::REPLY
    end
    
    trait :sending do
      status        Message::SENDING
    end
    
    trait :sent do
      status        Message::SENT
    end
    
    trait :settled do
      sent
      provider_cost { random_price() }
      our_cost      { random_price() }
    end

  end

end
