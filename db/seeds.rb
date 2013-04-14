# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

def rand_f( min, max )
  rand * (max-min) + min
end

def rand_i( min, max )
  min = min.to_i
  max = max.to_i
  rand(max-min) + min
end

def random_us_number()
  '+1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_ca_number()
  '+1%03d%03d%04d' % [ rand_i(201, 799), rand_i(100, 999), rand_i(0001, 9999) ]
end

def random_uk_number()
  '+44%04d%03d%03d' % [ rand_i(2000, 9999), rand_i(000, 999), rand_i(000, 999) ]
end

def random_answer()
  '%0.2f' % rand_f(0.01, 100.99)
end

# Add plan data
master_plan = AccountPlan.find_or_create_by_label( label: 'Unmetered' )
payg_plan = AccountPlan.find_or_create_by_label( label:'PAYG', month: 0, phone_add: 1, call_in_add: 0.02, sms_in_add: 0.02, sms_out_add: 0.02 )
dedicated_plan = AccountPlan.find_or_create_by_label( label:'Dedicated', month: 250, phone_add: 0, call_in_add: 0.01, sms_in_add: 0.01, sms_out_add: 0.01 )

# Add a test account (me!)
unless Rails.env.production? || Account.exists?( encrypted_twilio_account_sid: Account.encrypt(:twilio_account_sid, ENV['TWILIO_TEST_ACCOUNT_SID']) )
  test_account = Account.new label:'Test Account', auth_token: 'test', account_plan: payg_plan, description: 'My test account'
    test_account.twilio_account_sid = ENV['TWILIO_TEST_ACCOUNT_SID']
    test_account.twilio_auth_token = ENV['TWILIO_TEST_AUTH_TOKEN']
    test_account.save!
  
  # Add users
  test_user = test_account.users.create first_name: 'Jane', last_name: 'Doe', email: 'jane.doe@signalcloudapp.com', password: 'password', password_confirmation: 'password', roles: nil
  simple_user = test_account.users.create first_name: 'Joe', last_name: 'Bloggs', email: 'joe.bloggs@signalcloudapp.com', password: 'password', password_confirmation: 'password', roles: nil
  
  # Add example data for the test account
  test_numbers = {
    US: test_account.phone_numbers.create!( number: Twilio::VALID_NUMBER, twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) ),
    CA: test_account.phone_numbers.create!( number: '+17127005678', twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) ),
    GB: test_account.phone_numbers.create!( number: '+447540123456', twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) )
  }
  
  example_directory = test_account.phone_directories.create label: 'Example Directory', description: 'Example description.'
  example_directory.phone_directory_entries.create phone_number_id: test_numbers[:US].id, country: nil
  #test_numbers.each { |country,number| example_directory.phone_directory_entries.create country: country, phone_number_id: number.id }
  
  example_stencil = test_account.stencils.create!({ label: 'Example Stencil', primary: true, phone_directory_id: example_directory.id, seconds_to_live: 180,
    description: 'Example stencil for handling possibly fraudulent charges to a debit card.',
    question: 'Hello from Friendly Bank. We recently detected a possibly fraudulent charge using your debit card. To protect you, we have temporarily blocked the card. If you are making this purchase and would like us to unlock the card, please reply to this number with the amount of the transaction. If you believe this charge is fraudulent, please reply NO and we will contact you about next steps.',
    expected_denied_answer: 'NO',
    confirmed_reply: 'Thank you. We will unblock your card immediately. Please retry your purchase.',
    denied_reply: 'Thank you. We will contact you shortly to discuss next steps to protect your account.',
    failed_reply: 'We are sorry, but your answer does not match your records. For your safety we have blocked your card and we will contact you shortly to discuss next steps.',
    expired_reply: 'We are sorry, but we did not receive your reply. For your safety we have blocked your card and we will contact you shortly to discuss next steps.'
    })
  
  customer_numbers = []
  15.times { customer_numbers << random_us_number() }
  10.times { customer_numbers << random_ca_number() }
  10.times { customer_numbers << random_uk_number() }
  
  customer_numbers.shuffle.each do |customer_number|
    ticket = example_stencil.open_ticket( to_number: customer_number, expected_confirmed_answer: random_answer() )
    ticket.status = Ticket::STATUSES.sample
    ticket.save!
    if [ Ticket::CHALLENGE_SENT, Ticket::CONFIRMED, Ticket::DENIED, Ticket::FAILED, Ticket::EXPIRED ].include? ticket.status
      ticket.messages.build( to_number: ticket.to_number, from_number: ticket.from_number, body: ticket.question, message_kind: Message::CHALLENGE, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 5.seconds.ago, status: Message::SENT )
    end
    case ticket.status
      when Ticket::CONFIRMED
        ticket.messages.build( to_number: ticket.from_number, from_number: ticket.to_number, body: ticket.expected_confirmed_answer, direction: Message::DIRECTION_IN, provider_cost: 0.01, sent_at: 4.seconds.ago )
        ticket.messages.build( to_number: ticket.to_number, from_number: ticket.from_number, body: ticket.confirmed_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
      when Ticket::DENIED
        ticket.messages.build( to_number: ticket.from_number, from_number: ticket.to_number, body: ticket.expected_denied_answer, direction: Message::DIRECTION_IN, provider_cost: 0.01, sent_at: 4.seconds.ago )
        ticket.messages.build( to_number: ticket.to_number, from_number: ticket.from_number, body: ticket.denied_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
      when Ticket::FAILED
        ticket.messages.build( to_number: ticket.from_number, from_number: ticket.to_number, body: random_answer(), direction: Message::DIRECTION_IN, provider_cost: 0.01, sent_at: 4.seconds.ago )
        ticket.messages.build( to_number: ticket.to_number, from_number: ticket.from_number, body: ticket.failed_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
      when Ticket::EXPIRED
        ticket.messages.build( to_number: ticket.to_number, from_number: ticket.from_number, body: ticket.expired_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
    end
    ticket.save!
  end
end


# Master account tools
unless Account.exists?( encrypted_twilio_account_sid: Account.encrypt(:twilio_account_sid, ENV['TWILIO_MASTER_ACCOUNT_SID']) )
  master_account = Account.new label:'Master Account', account_plan: master_plan, description: 'Primary account'
    master_account.twilio_account_sid = ENV['TWILIO_MASTER_ACCOUNT_SID']
    master_account.twilio_auth_token = ENV['TWILIO_MASTER_AUTH_TOKEN']
    master_account.account_sid = '76f78f836d4563bf4824da02b506346d'
    master_account.auth_token = '0ee1ed9c635074d1a5fc452aa2aec6d1'
    master_account.save!
  
  master_user = master_account.users.build first_name: 'Ian', last_name: 'Lloyd', email: 'ian@signalcloudapp.com', password: ENV['TWILIO_MASTER_ACCOUNT_SID'], password_confirmation: ENV['TWILIO_MASTER_ACCOUNT_SID'], roles: User::ROLES
    master_user.save!
  
  master_phone_number = master_account.phone_numbers.create!( number: '+14242773034', twilio_phone_number_sid: 'PNb35b5f695c76e7f558956284204bcb45' )
  master_account.phone_directories.first.phone_directory_entries.create!( phone_number_id: master_phone_number.id, country: nil )
  
  master_account.stencils.create!({ label: 'Silly Example', primary: true, phone_directory_id: master_account.phone_directories.first.id, seconds_to_live: 15*60,
    description: 'A silly example to test functionality with friends and colleagues.',
    question: 'Who is cooler, Ian or Susie?',
    expected_confirmed_answer: 'Ian',
    expected_denied_answer: 'Susie',
    confirmed_reply: 'Spot on!',
    denied_reply: 'Are you sure?',
    failed_reply: 'Who is that?',
    expired_reply: 'You took way to long!'
    })
  
  master_account.stencils.create!({ label: 'Doctor Appointment Example', primary: false, phone_directory_id: master_account.phone_directories.first.id, seconds_to_live: 4*60*60,
    description: 'Example of using the service to confirm doctor appointments.',
    question: 'Reminder: Your appointment with Dr Ian is tomorrow at 08:30. To confirm this appt, reply with your postcode. To change your appt, reply CHANGE.',
    expected_denied_answer: 'CHANGE',
    confirmed_reply: 'Thank you for confirming your appointment with Dr Ian. We look forward to seeing you tomorrow.',
    denied_reply: 'Thank you for letting us know. We will call you today to reschedule your appointment.',
    failed_reply: 'Thank you for letting us know. We will call you today to reschedule your appointment.',
    expired_reply: 'We are sorry, but we have not received your response. We will call you today to reschedule your appointment.'
    })
  
  master_account.stencils.create!({ label: 'Fraud Transaction Example', primary: false, phone_directory_id: master_account.phone_directories.first.id, seconds_to_live: 5*60,
    description: 'Example stencil for handling possibly fraudulent charges to a debit card.',
    question: 'Hello from Friendly Bank. We recently detected a possibly fraudulent charge using your debit card. To protect you, we have temporarily blocked the card. If you are making this purchase and would like us to unlock the card, please reply to this number with the amount of the transaction. If you believe this charge is fraudulent, please reply NO and we will contact you about next steps.',
    expected_denied_answer: 'NO',
    confirmed_reply: 'Thank you. We will unblock your card immediately. Please retry your purchase.',
    denied_reply: 'Thank you. We will contact you shortly to discuss next steps to protect your account.',
    failed_reply: 'We are sorry, but your answer does not match your records. For your safety we have blocked your card and we will contact you shortly to discuss next steps.',
    expired_reply: 'We are sorry, but we did not receive your reply. For your safety we have blocked your card and we will contact you shortly to discuss next steps.'
    })
end
