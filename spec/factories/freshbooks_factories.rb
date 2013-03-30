FactoryGirl.define do

  factory :freshbooks_account, parent: :account do
    freshbooks_id       2
    
    after(:create) do |account, evaluator|
      # Create basics
      phone_number    = create(:phone_number, account: account)
      phone_directory = create(:phone_directory, account: account)
      create(:phone_directory_entry, phone_number: phone_number, phone_directory: phone_directory)
      appliance       = create(:appliance, account: account, phone_directory: phone_directory)
      
      # December 2012: 5 confirmed, 5 failed, 5 denied, 5 expired, 5 unsettled tickets (25; 55 ledger entries)
      create_tickets_for_month( appliance, '2012-12-01', 5 )

      # November 2012: 4 of each (20; 44 ledger entries)
      create_tickets_for_month( appliance, '2012-11-01', 4 )
      
      # January 2013: 3 of each (15; 33 ledger_entries)
      create_tickets_for_month( appliance, '2013-01-01', 3 )
    end
  end
  
end

def create_tickets_for_month( appliance, month, count )
  month = month.to_datetime unless month.is_a? DateTime
  month_start = month.beginning_of_month
  month_end = month.end_of_month - 1.hour
  
  count.times { open_and_configure_ticket( appliance, false, rand_datetime( month_start, month_end ), Ticket::CHALLENGE_SENT ) }
  [ Ticket::CONFIRMED, Ticket::FAILED, Ticket::DENIED, Ticket::EXPIRED ].each do |status|
    count.times { open_and_configure_ticket( appliance, true, rand_datetime( month_start, month_end ), status ) }
  end
end

def open_and_configure_ticket( appliance, settled=false, date_sent=nil, status=nil, outbound_price=0.04, inbound_price=0.01 )
  ticket = appliance.open_ticket( to_number: random_us_number(), from_number: appliance.phone_directory.phone_numbers.first.number )
  ticket.status = status || Ticket::STATUSES.sample
  ticket.created_at = date_sent if date_sent
  ticket.save!

  if [ Ticket::CHALLENGE_SENT, Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED ].include? ticket.status
    ticket.challenge_sent_at = ticket.created_at #rand_datetime( '2012-12-01'.to_datetime, '2012-12-31'.to_datetime )
    ticket.challenge_status = Message::SENT
    message = create( :challenge_message, ticket: ticket, provider_response: { test: 'test' }, sent_at: ticket.challenge_sent_at )
    if settled
      message.provider_cost = outbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end
  end

  if [ Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED ].include? ticket.status
    ticket.response_received_at = ticket.challenge_sent_at + rand_in_range( 1, appliance.seconds_to_live )
    ticket.reply_sent_at = ticket.response_received_at + rand_in_range( 1, 5 )
    message = create( :message, ticket: ticket, provider_response: { test: 'test' }, sent_at: ticket.response_received_at, direction: Message::DIRECTION_IN )
    if settled
      message.provider_cost = inbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end

    message = create( :reply_message, ticket: ticket, provider_response: { test: 'test' }, sent_at: ticket.reply_sent_at )
    if settled
      message.provider_cost = outbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end
  end

  if [ Ticket::EXPIRED ].include? ticket.status
    ticket.reply_sent_at = ticket.challenge_sent_at + appliance.seconds_to_live + rand_in_range( 1, 5 )
    message = create( :reply_message, ticket: ticket, provider_response: { test: 'test' }, sent_at: ticket.reply_sent_at )
    if settled
      message.provider_cost = outbound_price
      message.save!

      message.ledger_entry.settled_at = message.sent_at
      message.ledger_entry.save!
    end
  end

  ticket.save!
  return ticket
end
