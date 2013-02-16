def create_freshbooks_account(tickets_count=20)
  # Create account - this creates the entire universe of activity
  account = FactoryGirl.create :freshbooks_account
  appliance = FactoryGirl.create :freshbooks_appliance, account: account, phone_directory: account.phone_directories.first

  # Build interation history
  # appliance = account.appliances.last
  # pp appliance
  
  phone_number = account.phone_numbers.first
  tickets_count.times do
    ticket = appliance.open_ticket( to_number: random_us_number(), from_number: phone_number.number )
    ticket.save!
    ticket.status = Ticket::STATUSES.sample
    if [ Ticket::CHALLENGE_SENT, Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED ].include? ticket.status
      ticket.challenge_sent = rand_datetime_lastmonth()
      ticket.challenge_status = Message::SENT
      create( :challenge_message, ticket: ticket, provider_response: { test: 'test' }, sent_at: ticket.challenge_sent )
    end
    if [ Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED ].include? ticket.status
      ticket.response_received = ticket.challenge_sent + rand_in_range( 1, appliance.seconds_to_live )
      ticket.reply_sent = ticket.response_received + rand_in_range( 1, 30 )
      create( :reply_message, ticket: ticket, provider_response: { test: 'test' }, sent_at: ticket.reply_sent )
    end
    if [ Ticket::EXPIRED ].include? ticket.status
      ticket.reply_sent = ticket.challenge_sent + appliance.seconds_to_live + rand_in_range( 1, 30 )
      create( :reply_message, ticket: ticket, provider_response: { test: 'test' }, sent_at: ticket.reply_sent )
    end
    ticket.save!
  end
  
  return account
end

FactoryGirl.define do

  factory :freshbooks_account, parent: :account do
    freshbooks_id       2
    
    ignore do
      appliances_count 1
      phone_numbers_count 1
      phone_directories_count 1
    end
    after(:create) do |account, evaluator|
      FactoryGirl.create_list(:phone_number, evaluator.phone_numbers_count, account: account)
      FactoryGirl.create_list(:freshbooks_phone_directory, evaluator.phone_directories_count, account: account)
      FactoryGirl.create_list(:freshbooks_appliance, evaluator.appliances_count, label: 'test', account: account, phone_directory: account.phone_directories(true).first)
    end
  end
  
  factory :freshbooks_phone_directory, class: PhoneDirectory do
    label       'FreshBooks Directory'
    description 'A test directory for FreshBooks integration testing'
  end

  factory :freshbooks_appliance, parent: :appliance do
    label       'FreshBooks Appliance'
    description 'A test appliance for FreshBooks integration testing'
  end

end
