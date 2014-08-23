FactoryGirl.define do

  factory :conversation do
    customer_number           Twilio::VALID_NUMBER
    expires_at                180.seconds.from_now
    question                  { Faker::Hacker.say_something_smart }
    expected_confirmed_answer { Faker::Hacker.noun }
    expected_denied_answer    { Faker::Hacker.verb }
    confirmed_reply           { Faker::Hacker.say_something_smart }
    denied_reply              { Faker::Hacker.say_something_smart }
    failed_reply              { Faker::Hacker.say_something_smart }
    expired_reply             { Faker::Hacker.say_something_smart }
    
    trait :with_stencil do
      after(:build) do |object, evaluator|
        unless object.stencil.present?
          organization = object.internal_number.try(:organization) || build(:organization, :with_mock_comms)
          object.stencil = build :stencil, organization: organization
        end
      end
    end

    trait :with_internal_number do
      after(:build) do |object, evaluator|
        unless object.internal_number.present?
          organization = object.stencil.try(:organization) || build(:organization, :with_mock_comms)
          object.internal_number = build :phone_number, :with_gateway, organization: organization
        end
      end
    end
    
    trait :challenge_sent do
      workflow_state          'asked'
      challenge_sent_at       { DateTime.now }
      challenge_status        'sent'
    end

    trait :response_received do
      response_received_at    { DateTime.now }
      workflow_state          'received'
    end
    
    trait :reply_sent do
      reply_sent_at           { DateTime.now }
      reply_status            'sent'
    end
    
    trait :draft do
      workflow_state          'draft'
    end
    
    trait :asking do
      challenge_status        'sending'
      workflow_state          'asking'
    end

    trait :asked do
      asking
      challenge_sent_at       { DateTime.now }
      challenge_status        'sent'
      workflow_state          'asked'
    end
    
    trait :receiving do
      asked
      workflow_state          'receiving'
    end

    trait :received do
      receiving
      response_received_at    { DateTime.now }
      workflow_state          'received'
    end
    
    trait :confirming do
      sending_reply
      workflow_state          'confirming'
    end

    trait :confirmed do
      sent_reply
      workflow_state          'confirmed'
    end

    trait :denying do
      sending_reply
      workflow_state          'denying'
    end

    trait :denied do
      sent_reply
      workflow_state          'denied'
    end

    trait :failing do
      sending_reply
      workflow_state          'failing'
    end

    trait :failed do
      sent_reply
      workflow_state          'failed'
    end

    trait :expiring do
      sending_reply
      workflow_state          'expiring'
    end

    trait :expired do
      sent_reply
      workflow_state          'expired'
    end
    
    trait :errored do
      workflow_state          'errored'
    end
    
    trait :with_webhook_uri do
      webhook_uri             'https://eu.signalcloudapp.com/bucket'
    end
    
    trait :real do
      #double false
    end
    
    trait :mock do
      #double true
    end
    
    ##
    # Ultra awesome method (oh god) to automagically attach messages to this conversation based on the conversation's state
    trait :with_messages do
      after(:stub) do |conversation, evaluator|
        # Question message
        if %w( asking asked receiving received confirming confirmed denying denied failing failed expiring expired ).include? conversation.workflow_state
          conversation.messages << build_stubbed( :challenge_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.question )
        end

        # Answer message
        if %w( receiving received confirming confirmed ).include? conversation.workflow_state
          conversation.messages << build_stubbed( :response_message, conversation: conversation, from_number: conversation.customer_number, to_number: conversation.internal_number.number, body: conversation.expected_confirmed_answer )
        end

        # Response (confirm) message
        if %w( confirming confirmed ).include? conversation.workflow_state
          # Answer message defined above
          conversation.messages << build_stubbed( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.confirmed_reply )
        end

        # Response (deny) message
        if %w( denying denied ).include? conversation.workflow_state
          conversation.messages << build_stubbed( :response_message, conversation: conversation, from_number: conversation.customer_number, to_number: conversation.internal_number.number, body: conversation.expected_denied_answer )
          conversation.messages << build_stubbed( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.denied_reply )
        end

        # Response (fail) message
        if %w( failing failed ).include? conversation.workflow_state
          conversation.messages << build_stubbed( :response_message, conversation: conversation, from_number: conversation.customer_number, to_number: conversation.internal_number.number, body: 'walrus walrus walrus' )
          conversation.messages << build_stubbed( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.failed_reply )
        end

        # Response (expire) message
        if %w( expiring expired ).include? conversation.workflow_state
          conversation.messages << build_stubbed( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.expired_reply )
        end
      end
      after(:build) do |conversation, evaluator|
        # Question message
        if %w( asking asked receiving received confirming confirmed denying denied failing failed expiring expired ).include? conversation.workflow_state
          conversation.messages << build( :challenge_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.question )
        end

        # Answer message
        if %w( receiving received confirming confirmed ).include? conversation.workflow_state
          conversation.messages << build( :response_message, conversation: conversation, from_number: conversation.customer_number, to_number: conversation.internal_number.number, body: conversation.expected_confirmed_answer )
        end

        # Response (confirm) message
        if %w( confirming confirmed ).include? conversation.workflow_state
          # Answer message defined above
          conversation.messages << build( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.confirmed_reply )
        end

        # Response (deny) message
        if %w( denying denied ).include? conversation.workflow_state
          conversation.messages << build( :response_message, conversation: conversation, from_number: conversation.customer_number, to_number: conversation.internal_number.number, body: conversation.expected_denied_answer )
          conversation.messages << build( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.denied_reply )
        end

        # Response (fail) message
        if %w( failing failed ).include? conversation.workflow_state
          conversation.messages << build( :response_message, conversation: conversation, from_number: conversation.customer_number, to_number: conversation.internal_number.number, body: 'walrus walrus walrus' )
          conversation.messages << build( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.failed_reply )
        end

        # Response (expire) message
        if %w( expiring expired ).include? conversation.workflow_state
          conversation.messages << build( :reply_message, conversation: conversation, to_number: conversation.customer_number, from_number: conversation.internal_number.number, body: conversation.expired_reply )
        end
      end
    end

    ##
    # Intended for internal use only
    trait :sending_reply do
      received
      reply_status            'sending'      
    end
    
    ##
    # Intended for internal use 
    trait :sent_reply do
      sending_reply
      reply_sent_at           { DateTime.now }
      reply_status            'sent'
    end
    
  end

end
