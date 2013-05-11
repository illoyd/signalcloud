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

# Master organization tools
unless Organization.exists?( encrypted_twilio_account_sid: Organization.encrypt(:twilio_account_sid, ENV['TWILIO_MASTER_ACCOUNT_SID']) )
  master_organization = Organization.new label:'Master Organization', account_plan: master_plan, description: 'Primary organization'
    master_organization.twilio_account_sid = ENV['TWILIO_MASTER_ACCOUNT_SID']
    master_organization.twilio_auth_token = ENV['TWILIO_MASTER_AUTH_TOKEN']
    master_organization.twilio_application_sid = ENV['TWILIO_APPLICATION']
    master_organization.sid = '76f78f836d4563bf4824da02b506346d'
    master_organization.auth_token = '0ee1ed9c635074d1a5fc452aa2aec6d1'
    master_organization.save!
  
  master_user = master_organization.users.build first_name: 'Ian', last_name: 'Lloyd', email: 'ian@signalcloudapp.com', password: ENV['SEED_PASSWORD'] || ENV['TWILIO_MASTER_ACCOUNT_SID'], password_confirmation: ENV['SEED_PASSWORD'] || ENV['TWILIO_MASTER_ACCOUNT_SID'], roles: User::ROLES
    master_user.save!
  
  master_phone_number = master_organization.phone_numbers.create!( number: '+1 202-601-3854', twilio_phone_number_sid: 'PNf7abf4d06e5faecb7d6878fa37b8cdc3' )
  master_phone_number_gb = master_organization.phone_numbers.create!( number: '+44 1753 254372', twilio_phone_number_sid: 'PNa11b228979b0759de22e39a8e6f8585c' )
  master_organization.phone_books.first.phone_book_entries.create!( phone_number_id: master_phone_number.id, country: nil )
  master_organization.phone_books.first.phone_book_entries.create!( phone_number_id: master_phone_number_gb.id, country: 'GB' )
  
  master_organization.stencils.create!({ label: 'Are you human?', primary: true, phone_book_id: master_organization.phone_books.first.id, seconds_to_live: 15*60,
    description: 'A simple test to see if the recipient can do simple math.',
    question: 'Are you human. What is two plus two? (Answer with numbers only!)',
    expected_confirmed_answer: '4',
    expected_denied_answer: 'four',
    confirmed_reply: 'Yup, you are definitely human!',
    denied_reply: 'Hey, you have to answer only with numbers!',
    failed_reply: 'Uh oh...',
    expired_reply: 'You took way too long!'
    })
  
  master_organization.stencils.create!({ label: 'Silly Example', primary: true, phone_book_id: master_organization.phone_books.first.id, seconds_to_live: 15*60,
    description: 'A silly example to test functionality with friends and colleagues.',
    question: 'Who is cooler, Ian or Susie?',
    expected_confirmed_answer: 'Ian',
    expected_denied_answer: 'Susie',
    confirmed_reply: 'Spot on!',
    denied_reply: 'Are you sure?',
    failed_reply: 'Who is that?',
    expired_reply: 'You took way too long!'
    })
  
  master_organization.stencils.create!({ label: 'Doctor Appointment Example', primary: false, phone_book_id: master_organization.phone_books.first.id, seconds_to_live: 4*60*60,
    description: 'Example of using the service to confirm doctor appointments.',
    question: 'Reminder: Your appointment with Dr Ian is tomorrow at 08:30. To confirm this appt, reply with your postcode. To change your appt, reply CHANGE.',
    expected_denied_answer: 'CHANGE',
    confirmed_reply: 'Thank you for confirming your appointment with Dr Ian. We look forward to seeing you tomorrow.',
    denied_reply: 'Thank you for letting us know. We will call you today to reschedule your appointment.',
    failed_reply: 'Thank you for letting us know. We will call you today to reschedule your appointment.',
    expired_reply: 'We are sorry, but we have not received your response. We will call you today to reschedule your appointment.'
    })
  
  master_organization.stencils.create!({ label: 'Fraud Transaction Example', primary: false, phone_book_id: master_organization.phone_books.first.id, seconds_to_live: 5*60,
    description: 'Example stencil for handling possibly fraudulent charges to a debit card.',
    question: 'Hello from Friendly Bank. We recently detected a possibly fraudulent charge using your debit card. To protect you, we have temporarily blocked the card. If you are making this purchase and would like us to unlock the card, please reply to this number with the amount of the transaction. If you believe this charge is fraudulent, please reply NO and we will contact you about next steps.',
    expected_denied_answer: 'NO',
    confirmed_reply: 'Thank you. We will unblock your card immediately. Please retry your purchase.',
    denied_reply: 'Thank you. We will contact you shortly to discuss next steps to protect your organization.',
    failed_reply: 'We are sorry, but your answer does not match your records. For your safety we have blocked your card and we will contact you shortly to discuss next steps.',
    expired_reply: 'We are sorry, but we did not receive your reply. For your safety we have blocked your card and we will contact you shortly to discuss next steps.'
    })
end

# Add a test organization for the development environment
unless Rails.env.production? || Organization.exists?( encrypted_twilio_account_sid: Organization.encrypt(:twilio_account_sid, ENV['TWILIO_TEST_ACCOUNT_SID']) )
  test_organization = Organization.new label:'Test Account', auth_token: 'test', account_plan: payg_plan, description: 'My test organization'
    test_organization.twilio_account_sid = ENV['TWILIO_TEST_ACCOUNT_SID']
    test_organization.twilio_auth_token = ENV['TWILIO_TEST_AUTH_TOKEN']
    test_organization.save!
  
  # Add users
  test_user = test_organization.users.create first_name: 'Jane', last_name: 'Doe', email: 'jane.doe@signalcloudapp.com', password: 'password', password_confirmation: 'password', roles: User::ROLES
  simple_user = test_organization.users.create first_name: 'Joe', last_name: 'Bloggs', email: 'joe.bloggs@signalcloudapp.com', password: 'password', password_confirmation: 'password', roles: nil
  
  # Add example data for the test organization
  test_numbers = {
    US: test_organization.phone_numbers.create!( number: Twilio::VALID_NUMBER, twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) ),
    CA: test_organization.phone_numbers.create!( number: '+17127005678', twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) ),
    GB: test_organization.phone_numbers.create!( number: '+447540123456', twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) )
  }
  
  example_book = test_organization.phone_books.create label: 'Example Book', description: 'Example description.'
  example_book.phone_book_entries.create phone_number_id: test_numbers[:US].id, country: nil
  #test_numbers.each { |country,number| example_book.phone_book_entries.create country: country, phone_number_id: number.id }
  
  example_stencil = test_organization.stencils.create!({ label: 'Example Stencil', primary: true, phone_book_id: example_book.id, seconds_to_live: 180,
    description: 'Example stencil for handling possibly fraudulent charges to a debit card.',
    question: 'Hello from Friendly Bank. We recently detected a possibly fraudulent charge using your debit card. To protect you, we have temporarily blocked the card. If you are making this purchase and would like us to unlock the card, please reply to this number with the amount of the transaction. If you believe this charge is fraudulent, please reply NO and we will contact you about next steps.',
    expected_denied_answer: 'NO',
    confirmed_reply: 'Thank you. We will unblock your card immediately. Please retry your purchase.',
    denied_reply: 'Thank you. We will contact you shortly to discuss next steps to protect your organization.',
    failed_reply: 'We are sorry, but your answer does not match your records. For your safety we have blocked your card and we will contact you shortly to discuss next steps.',
    expired_reply: 'We are sorry, but we did not receive your reply. For your safety we have blocked your card and we will contact you shortly to discuss next steps.'
    })
  
  customer_numbers = []
  15.times { customer_numbers << random_us_number() }
  10.times { customer_numbers << random_ca_number() }
  10.times { customer_numbers << random_uk_number() }
  
  customer_numbers.shuffle.each do |customer_number|
    conversation = example_stencil.open_conversation( to_number: customer_number, expected_confirmed_answer: random_answer() )
    conversation.status = Conversation::STATUSES.sample
    conversation.save!
    if [ Conversation::CHALLENGE_SENT, Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED, Conversation::EXPIRED ].include? conversation.status
      conversation.messages.build( to_number: conversation.to_number, from_number: conversation.from_number, body: conversation.question, message_kind: Message::CHALLENGE, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 5.seconds.ago, status: Message::SENT )
    end
    case conversation.status
      when Conversation::CONFIRMED
        conversation.messages.build( to_number: conversation.from_number, from_number: conversation.to_number, body: conversation.expected_confirmed_answer, direction: Message::DIRECTION_IN, provider_cost: 0.01, sent_at: 4.seconds.ago )
        conversation.messages.build( to_number: conversation.to_number, from_number: conversation.from_number, body: conversation.confirmed_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
      when Conversation::DENIED
        conversation.messages.build( to_number: conversation.from_number, from_number: conversation.to_number, body: conversation.expected_denied_answer, direction: Message::DIRECTION_IN, provider_cost: 0.01, sent_at: 4.seconds.ago )
        conversation.messages.build( to_number: conversation.to_number, from_number: conversation.from_number, body: conversation.denied_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
      when Conversation::FAILED
        conversation.messages.build( to_number: conversation.from_number, from_number: conversation.to_number, body: random_answer(), direction: Message::DIRECTION_IN, provider_cost: 0.01, sent_at: 4.seconds.ago )
        conversation.messages.build( to_number: conversation.to_number, from_number: conversation.from_number, body: conversation.failed_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
      when Conversation::EXPIRED
        conversation.messages.build( to_number: conversation.to_number, from_number: conversation.from_number, body: conversation.expired_reply, message_kind: Message::REPLY, direction: Message::DIRECTION_OUT, provider_cost: 0.01, sent_at: 3.seconds.ago, status: Message::SENT )
    end
    conversation.save!
  end
end


# Add a performance testing organization where necessary (will not appear in Development)
unless Organization.exists?( encrypted_twilio_account_sid: Organization.encrypt(:twilio_account_sid, ENV['TWILIO_TEST_ACCOUNT_SID']) )

  perf_organization = Organization.new label:'Performance', auth_token: 'test', account_plan: master_plan, description: 'Performance testing'
    perf_organization.twilio_account_sid = ENV['TWILIO_TEST_ACCOUNT_SID']
    perf_organization.twilio_auth_token = ENV['TWILIO_TEST_AUTH_TOKEN']
    perf_organization.save!

  perf_user = perf_organization.users.build first_name: 'Performance', last_name: 'User', email: 'hello@signalcloudapp.com', password: ENV['SEED_PASSWORD'] || ENV['TWILIO_MASTER_ACCOUNT_SID'], password_confirmation: ENV['SEED_PASSWORD'] || ENV['TWILIO_MASTER_ACCOUNT_SID'], roles: User::ROLES
    perf_user.save!
  
  perf_phone_number = perf_organization.phone_numbers.create!( number: Twilio::VALID_NUMBER, twilio_phone_number_sid: 'PX'+SecureRandom.hex(16) )
  perf_organization.phone_books.first.phone_book_entries.create!( phone_number_id: perf_phone_number.id, country: nil )

  perf_organization.stencils.create!({
    label: 'Performance Example',
    primary: true,
    phone_book_id: perf_organization.phone_books.first.id,
    seconds_to_live: 3*60,
    description: 'Speed test performance example.',
    question: 'Hello, world! (Y/N)',
    expected_confirmed_answer: 'Y',
    expected_denied_answer: 'N',
    confirmed_reply: '"Yes" received',
    denied_reply: '"No" received',
    failed_reply: 'Unknown answer received',
    expired_reply: 'No answer received'
    })
  
end
