FactoryGirl.define do

  factory :message do
    conversation
    workflow_state     'pending'
    challenge
    
#     after(:create) do |message, evaluator|
#       FactoryGirl.create(:ledger_entry, organization: message.conversation.stencil.organization, item: message, value: message.cost, narrative: LedgerEntry::OUTBOUND_SMS_NARRATIVE )
#     end
#     
    trait :with_costs do
      provider_cost    { random_cost() }
      our_cost         { random_cost() }
    end
    
    trait :with_twilio_sid do
      provider_sid        'SMe7a99c10b98ee37aa680ee0617c76d21'
    end
    
    trait :with_random_twilio_sid do
      provider_sid        { 'SM' + SecureRandom.hex(16) }
    end
    
    trait :with_provider_response do
      ignore do
        remote_sid { conversation.stencil.organization.communication_gateway.twilio_account_sid rescue 'TEST' }
      end
      provider_response { {
                          "sid" => provider_sid,
                          "date_created" => DateTime.now,
                          "date_updated" => DateTime.now,
                          "date_sent" => nil,
                          "account_sid" => remote_sid,
                          "to" => conversation.customer_number,
                          "from" => conversation.internal_number,
                          "body" => conversation.question,
                          "status" => "queued",
                          "direction" => "outbound-api",
                          "api_version" => "2010-04-01",
                          "price" => nil,
                          "uri" => "\/2010-04-01\/Accounts\/#{remote_sid}\/SMS\/Messages\/#{provider_sid}.json"
                        } }
    end

    factory :challenge_message do
      challenge
    end

    factory :response_message do
      response
    end

    factory :reply_message do
      reply
    end

    trait :challenge do
      message_kind  Message::CHALLENGE
      direction     Message::OUT
    end

    trait :response do
      message_kind  Message::RESPONSE
      direction     Message::IN
    end

    trait :reply do
      message_kind  Message::REPLY
      direction     Message::OUT
    end
    
    trait :draft do
      workflow_state 'pending'
    end
    
    trait :pending do
      draft
    end
    
    trait :sending do
      workflow_state 'sending'
    end
    
    trait :sent do
      workflow_state 'sent'
    end
    
    trait :settled do
      sent
      provider_cost { random_price() }
      our_cost      { random_price() }
    end

  end

end
