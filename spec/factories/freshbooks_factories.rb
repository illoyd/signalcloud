FactoryGirl.define do

  factory :freshbooks_account, parent: :organization do
    association :account_plan,       factory: :payg_account_plan
    association :accounting_gateway, factory: [ :fresh_books_accounting_gateway, :ready ]
    
    after(:create) do |organization, evaluator|
      # Create basics
      phone_number    = create(:phone_number, organization: organization)
      phone_book      = create(:phone_book, organization: organization)
      create(:phone_book_entry, phone_number: phone_number, phone_book: phone_book)
      stencil         = create(:stencil, organization: organization, phone_book: phone_book)
    end
    
    trait :with_data do
      with_november_data
      with_december_data
      with_january_data
    end
    
    trait :with_november_data do
      after(:create) do |organization, evaluator|
        # November 2012: 2 confirmed, 2 failed, 2 denied, 2 expired, 2 unsettled conversations (10; 22 ledger entries)
        create_conversations_for_month( organization.stencils.last, '2012-11-01', 2 )
      end
    end
    
    trait :with_december_data do
      after(:create) do |organization, evaluator|
        # December 2012: 3 confirmed, 3 failed, 3 denied, 3 expired, 3 unsettled conversations (15; 33 ledger entries)
        create_conversations_for_month( organization.stencils.last, '2012-12-01', 3 )
      end
    end
    
    trait :with_january_data do
      after(:create) do |organization, evaluator|
        # December 2012: 1 confirmed, 1 failed, 1 denied, 1 expired, 1 unsettled conversations (5; 11 ledger entries)
        create_conversations_for_month( organization.stencils.last, '2013-01-01', 1 )
      end
    end
  end
  
end

def create_conversations_for_month( stencil, month, count )
  month = month.to_datetime unless month.is_a? DateTime
  month_start = month.beginning_of_month
  month_end = month.end_of_month - 1.hour
  
  count.times { open_and_configure_conversation( stencil, false, rand_datetime( month_start, month_end ), Conversation::CHALLENGE_SENT ) }
  [ Conversation::CONFIRMED, Conversation::FAILED, Conversation::DENIED, Conversation::EXPIRED ].each do |status|
    count.times { open_and_configure_conversation( stencil, true, rand_datetime( month_start, month_end ), status ) }
  end
end

def open_and_configure_conversation( stencil, settled=false, date_sent=nil, status=nil, outbound_price=-0.04, inbound_price=-0.01 )
  conversation = stencil.open_conversation( to_number: random_us_number(), from_number: stencil.phone_book.phone_numbers.first.number )
  conversation.status = status || Conversation::STATUSES.sample
  conversation.created_at = date_sent if date_sent

  if [ Conversation::CHALLENGE_SENT, Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED, Conversation::EXPIRED ].include? conversation.status
    conversation.challenge_sent_at = conversation.created_at #rand_datetime( '2012-12-01'.to_datetime, '2012-12-31'.to_datetime )
    conversation.challenge_status = Message::SENT
    build_message conversation, :challenge_message, settled, conversation.challenge_sent_at, outbound_price
  end

  if [ Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED ].include? conversation.status
    conversation.response_received_at = conversation.challenge_sent_at + rand_in_range( 1, stencil.seconds_to_live )
    conversation.reply_sent_at = conversation.response_received_at + rand_in_range( 1, 5 )
    build_message conversation, :response_message, settled, conversation.response_received_at, inbound_price
    build_message conversation, :reply_message, settled, conversation.reply_sent_at, outbound_price
  end

  if [ Conversation::EXPIRED ].include? conversation.status
    conversation.reply_sent_at = conversation.challenge_sent_at + stencil.seconds_to_live + rand_in_range( 1, 5 )
    build_message conversation, :reply_message, settled, conversation.reply_sent_at, outbound_price
  end

  conversation.save!
  return conversation
end

def build_message( conversation, kind, settled, sent_at, price )
  message = build( kind, conversation: conversation, provider_response: { test: 'test' }, sent_at: sent_at )
  conversation.messages << message
  if settled
    message.provider_cost = price
    message.ledger_entry.settled_at = message.sent_at
  end
end
