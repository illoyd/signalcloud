FactoryGirl.define do

  factory :freshbooks_account, parent: :account do
    freshbooks_id       2
    
    after(:create) do |account, evaluator|
      # Create basics
      phone_number    = create(:phone_number, account: account)
      phone_book = create(:phone_book, account: account)
      create(:phone_book_entry, phone_number: phone_number, phone_book: phone_book)
      stencil       = create(:stencil, account: account, phone_book: phone_book)
      
      # December 2012: 5 confirmed, 5 failed, 5 denied, 5 expired, 5 unsettled conversations (25; 55 ledger entries)
      create_conversations_for_month( stencil, '2012-12-01', 5 )

      # November 2012: 4 of each (20; 44 ledger entries)
      create_conversations_for_month( stencil, '2012-11-01', 4 )
      
      # January 2013: 3 of each (15; 33 ledger_entries)
      create_conversations_for_month( stencil, '2013-01-01', 3 )
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

def open_and_configure_conversation( stencil, settled=false, date_sent=nil, status=nil, outbound_price=0.04, inbound_price=0.01 )
  conversation = stencil.open_conversation( to_number: random_us_number(), from_number: stencil.phone_book.phone_numbers.first.number )
  conversation.status = status || Conversation::STATUSES.sample
  conversation.created_at = date_sent if date_sent
  conversation.save!

  if [ Conversation::CHALLENGE_SENT, Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED, Conversation::EXPIRED ].include? conversation.status
    conversation.challenge_sent_at = conversation.created_at #rand_datetime( '2012-12-01'.to_datetime, '2012-12-31'.to_datetime )
    conversation.challenge_status = Message::SENT
    message = create( :challenge_message, conversation: conversation, provider_response: { test: 'test' }, sent_at: conversation.challenge_sent_at )
    if settled
      message.provider_cost = outbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end
  end

  if [ Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED ].include? conversation.status
    conversation.response_received_at = conversation.challenge_sent_at + rand_in_range( 1, stencil.seconds_to_live )
    conversation.reply_sent_at = conversation.response_received_at + rand_in_range( 1, 5 )
    message = create( :message, conversation: conversation, provider_response: { test: 'test' }, sent_at: conversation.response_received_at, direction: Message::DIRECTION_IN )
    if settled
      message.provider_cost = inbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end

    message = create( :reply_message, conversation: conversation, provider_response: { test: 'test' }, sent_at: conversation.reply_sent_at )
    if settled
      message.provider_cost = outbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end
  end

  if [ Conversation::EXPIRED ].include? conversation.status
    conversation.reply_sent_at = conversation.challenge_sent_at + stencil.seconds_to_live + rand_in_range( 1, 5 )
    message = create( :reply_message, conversation: conversation, provider_response: { test: 'test' }, sent_at: conversation.reply_sent_at )
    if settled
      message.provider_cost = outbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end
  end

  conversation.save!
  return conversation
end
