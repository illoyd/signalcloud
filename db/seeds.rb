# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

def rand_in_range(from, to)
  rand * (to - from) + from
end

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

def rand_datetime(from, to=Time.now)
  Time.at(rand_in_range(from.to_f, to.to_f))
end

def white_house_address
  Address.new( 'Barack', 'Obama', 'theprez@signalcloudapp.com', '+12021234568', 'The White House', '1600 Pennsylvania Ave NW', 'Washington', 'DC', '20500', 'US' )
end

# Create users for all environments
master_user = User.create_with(name: ENV['SEED_USER'] || 'Johnny Appleseed', password: ENV['TWILIO_MASTER_ACCOUNT_SID'], password_confirmation: ENV['TWILIO_MASTER_ACCOUNT_SID']).find_or_create_by!(email: ENV['SEED_EMAIL'] || 'seed@signalcloudapp.com')

# Create users only for non-production environments
unless Rails.env.production?
  perf_user = User.create_with(nickname: 'Perf', name: 'Performance User', password: ENV['TWILIO_MASTER_ACCOUNT_SID'], password_confirmation: ENV['TWILIO_MASTER_ACCOUNT_SID']).find_or_create_by!(email: 'hello@signalcloudapp.com')
  simple_user = User.create_with(nickname: 'Joe', name: 'Joseph Bloggs',   password: 'password', password_confirmation: 'password').find_or_create_by(email: 'joe.bloggs@signalcloudapp.com')
  test_user = User.create_with(nickname: 'Jane', name: 'Jane Doe',         password: 'password', password_confirmation: 'password').find_or_create_by(email: 'jane.doe@signalcloudapp.com')
end

# Add plan data
master_plan = AccountPlan.find_or_create_by( label: 'Unmetered' )
payg_plan = AccountPlan.create_with( month: 0, phone_add: -1, call_in_add: -0.02, sms_in_add: -0.02, sms_out_add: -0.02, default: true ).find_or_create_by( label:'PAYG' )
dedicated_plan = AccountPlan.create_with( month: -250, phone_add: 0, call_in_add: -0.01, sms_in_add: -0.01, sms_out_add: -0.01 ).find_or_create_by( label:'Dedicated' )

# Master organization tools
unless Organization.exists?( sid: '76f78f836d4563bf4824da02b506346d' )
  org = Organization.new({
    label:          'Master',
    account_plan:   master_plan,
    description:    'Primary organization',
    sid:            '76f78f836d4563bf4824da02b506346d',
    auth_token:     '0ee1ed9c635074d1a5fc452aa2aec6d1',
    workflow_state: 'ready',
    owner:          master_user
  })
  org.billing_address = white_house_address
  org.save!

  # Attach users
  org.user_roles.create user: master_user, roles: UserRole::ROLES
  
  # Build communication gateway
  comm_gateway = TwilioCommunicationGateway.create!({
    organization:       org,
    remote_sid:         ENV['TWILIO_MASTER_ACCOUNT_SID'],
    remote_token:       ENV['TWILIO_MASTER_AUTH_TOKEN'],
    remote_application: ENV['TWILIO_APPLICATION'],
    workflow_state:     'ready'
  })
  
  master_phone_number = org.phone_numbers.create!( number: '+1 202-601-3854', workflow_state: :active, provider_sid: 'PNf7abf4d06e5faecb7d6878fa37b8cdc3', communication_gateway: comm_gateway )
  master_phone_number_gb = org.phone_numbers.create!( number: '+44 1753 254372', workflow_state: :active, provider_sid: 'PNa11b228979b0759de22e39a8e6f8585c', communication_gateway: comm_gateway )
  org.phone_books.first.phone_book_entries.create!( phone_number_id: master_phone_number.id, country: nil )
  org.phone_books.first.phone_book_entries.create!( phone_number_id: master_phone_number_gb.id, country: 'GB' )
  
  org.stencils.create!({ label: 'Are you human?', primary: true, phone_book_id: org.phone_books.first.id, seconds_to_live: 15*60,
    description: 'A simple test to see if the recipient can do simple math.',
    question: 'Let\'s see if you\'re human. What is two plus two? (Answer with numbers only!)',
    expected_confirmed_answer: '4',
    expected_denied_answer: 'four',
    confirmed_reply: 'Yup, you are definitely human!',
    denied_reply: 'Hey, you have to answer only with numbers!',
    failed_reply: 'Uh oh...',
    expired_reply: 'You took way too long!'
    })
  
  org.stencils.create!({ label: 'Silly Example', primary: true, phone_book_id: org.phone_books.first.id, seconds_to_live: 15*60,
    description: 'A silly example to test functionality with friends and colleagues.',
    question: 'Who is cooler, Ian or Susie?',
    expected_confirmed_answer: 'Ian',
    expected_denied_answer: 'Susie',
    confirmed_reply: 'Spot on!',
    denied_reply: 'Are you sure?',
    failed_reply: 'Who is that?',
    expired_reply: 'You took way too long!'
    })
  
  org.stencils.create!({ label: 'Doctor Appointment Example', primary: false, phone_book_id: org.phone_books.first.id, seconds_to_live: 4*60*60,
    description: 'Example of using the service to confirm doctor appointments.',
    question: 'Reminder: Your appointment with Dr Ian is tomorrow at 08:30. To confirm this appt, reply with your postcode. To change your appt, reply CHANGE.',
    expected_denied_answer: 'CHANGE',
    confirmed_reply: 'Thank you for confirming your appointment with Dr Ian. We look forward to seeing you tomorrow.',
    denied_reply: 'Thank you for letting us know. We will call you today to reschedule your appointment.',
    failed_reply: 'Thank you for letting us know. We will call you today to reschedule your appointment.',
    expired_reply: 'We are sorry, but we have not received your response. We will call you today to reschedule your appointment.'
    })
  
  org.stencils.create!({ label: 'Fraud Transaction Example', primary: false, phone_book_id: org.phone_books.first.id, seconds_to_live: 5*60,
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
unless Rails.env.production? || Organization.exists?( sid: '00000000000000000000000000000000' )
  org = Organization.create!({
    label:          'Test Account',
    sid:            '00000000000000000000000000000000',
    auth_token:     '0ee1ed9c635074d1a5fc452aa2aec6d1',
    account_plan:   payg_plan,
    description:    'My test organization',
    workflow_state: 'trial',
    owner:          test_user
  })

  # Attach users
  org.user_roles.create! user: test_user, roles: UserRole::ROLES
  org.user_roles.create! user: simple_user, roles: nil
  
  # Build communication gateway
  comm_gateway = TwilioCommunicationGateway.create!({
    organization:       org,
    remote_sid:         ENV['TWILIO_TEST_ACCOUNT_SID'],
    remote_token:       ENV['TWILIO_TEST_AUTH_TOKEN'],
    remote_application: ENV['TWILIO_APPLICATION'],
    workflow_state:     'ready'
  })
  
  # Add example data for the test organization
  test_numbers = {
    US: org.phone_numbers.create!( number: Twilio::VALID_NUMBER, provider_sid: 'XX'+SecureRandom.hex(16), communication_gateway: comm_gateway ),
    CA: org.phone_numbers.create!( number: '+17127005678', provider_sid: 'XX'+SecureRandom.hex(16), communication_gateway: comm_gateway ),
    GB: org.phone_numbers.create!( number: '+447540123456', provider_sid: 'XX'+SecureRandom.hex(16), communication_gateway: comm_gateway )
  }
  
  example_book = org.phone_books.create label: 'Example Book', description: 'Example description.'
  example_book.phone_book_entries.create phone_number_id: test_numbers[:US].id, country: nil
  #test_numbers.each { |country,number| example_book.phone_book_entries.create country: country, phone_number_id: number.id }
  
  example_stencil = org.stencils.create!({ label: 'Example Stencil', primary: true, phone_book_id: example_book.id, seconds_to_live: 180,
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
  date_from = 2.weeks.ago
  date_to   = DateTime.now
  outbound_cost = -0.03
  inbound_cost  = -0.02
  
  customer_numbers.shuffle.each do |customer_number|
    conversation = example_stencil.open_conversation( customer_number: customer_number, expected_confirmed_answer: random_answer() )
    conversation.workflow_state = Conversation.workflow_spec.state_names.sample
    conversation.created_at = rand_datetime( date_from, date_to );
    conversation.save!
    if [ Conversation::CHALLENGE_SENT, Conversation::CONFIRMED, Conversation::DENIED, Conversation::FAILED, Conversation::EXPIRED ].include? conversation.workflow_state
      conversation.challenge_sent_at = conversation.created_at
      conversation.messages.build( to_number: conversation.customer_number, from_number: conversation.internal_number, body: conversation.question, message_kind: Message::CHALLENGE, direction: Message::OUT, cost: outbound_cost, sent_at: conversation.challenge_sent_at, workflow_state: :sent )
    end

    case conversation.workflow_state
      when Conversation::CONFIRMED
        conversation.response_received_at = conversation.challenge_sent_at + rand_in_range( 1, conversation.stencil.seconds_to_live )
        conversation.reply_sent_at        = conversation.response_received_at + rand_in_range( 1, 5 )
        conversation.messages.build( to_number: conversation.internal_number, from_number: conversation.customer_number, body: conversation.expected_confirmed_answer, direction: Message::IN, cost: inbound_cost, sent_at: conversation.response_received_at, workflow_state: :received )
        conversation.messages.build( to_number: conversation.customer_number, from_number: conversation.internal_number, body: conversation.confirmed_reply, message_kind: Message::REPLY, direction: Message::OUT, cost: outbound_cost, sent_at: conversation.reply_sent_at, workflow_state: :sent )

      when Conversation::DENIED
        conversation.response_received_at = conversation.challenge_sent_at + rand_in_range( 1, conversation.stencil.seconds_to_live )
        conversation.reply_sent_at        = conversation.response_received_at + rand_in_range( 1, 5 )
        conversation.messages.build( to_number: conversation.internal_number, from_number: conversation.customer_number, body: conversation.expected_denied_answer, direction: Message::IN, cost: inbound_cost, sent_at: conversation.response_received_at, workflow_state: :received )
        conversation.messages.build( to_number: conversation.customer_number, from_number: conversation.internal_number, body: conversation.denied_reply, message_kind: Message::REPLY, direction: Message::OUT, cost: outbound_cost, sent_at: conversation.reply_sent_at, workflow_state: :sent )

      when Conversation::FAILED
        conversation.response_received_at = conversation.challenge_sent_at + rand_in_range( 1, conversation.stencil.seconds_to_live )
        conversation.reply_sent_at        = conversation.response_received_at + rand_in_range( 1, 5 )
        conversation.messages.build( to_number: conversation.internal_number, from_number: conversation.customer_number, body: random_answer(), direction: Message::IN, cost: inbound_cost, sent_at: conversation.response_received_at, workflow_state: :received )
        conversation.messages.build( to_number: conversation.customer_number, from_number: conversation.internal_number, body: conversation.failed_reply, message_kind: Message::REPLY, direction: Message::OUT, cost: outbound_cost, sent_at: conversation.reply_sent_at, workflow_state: :sent )

      when Conversation::EXPIRED
        conversation.reply_sent_at        = conversation.challenge_sent_at + conversation.stencil.seconds_to_live + rand_in_range( 1, 5 )
        conversation.messages.build( to_number: conversation.customer_number, from_number: conversation.internal_number, body: conversation.expired_reply, message_kind: Message::REPLY, direction: Message::OUT, cost: outbound_cost, sent_at: conversation.reply_sent_at, workflow_state: :sent )
    end
    #conversation.updated_at = [ conversation.created_at, conversation.challenge_sent_at, conversation.response_received_at, conversation.reply_sent_at ].reject_imax
    conversation.save!
  end
  
  invoice = org.invoices.create( workflow_state: 'settled', date_from: 4.weeks.ago, date_to: 1.week.ago, freshbooks_invoice_id: 431652, public_link: 'https://signalcloud.freshbooks.com/view/yBkg7e8B9CChqJk', internal_link: 'https://signalcloud.freshbooks.com/invoices/431652' )
    invoice.capture_uninvoiced_ledger_entries!
    invoice.save!
end


# Add a performance testing organization where necessary (will not appear in Development)
unless Rails.env.production? || Organization.exists?( sid: '00000000000000000000000000000000' )

  org = Organization.create!({
    label:          'Performance',
    sid:            '00000000000000000000000000000000',
    auth_token:     '0ee1ed9c635074d1a5fc452aa2aec6d1',
    account_plan:   payg_plan,
    description:    'Performance testing',
    workflow_state: 'trial',
    owner:          perf_user
  })

  # Attach users
  org.user_roles.create! user: perf_user, roles: UserRole::ROLES  
  
  # Build communication gateway
  comm_gateway = TwilioCommunicationGateway.create!({
    organization:       org,
    remote_sid:         ENV['TWILIO_TEST_ACCOUNT_SID'],
    remote_token:       ENV['TWILIO_TEST_AUTH_TOKEN'],
    remote_application: ENV['TWILIO_APPLICATION'],
    workflow_state:     'ready'
  })
  
  perf_phone_number = org.phone_numbers.create!( number: Twilio::VALID_NUMBER, provider_sid: 'PX'+SecureRandom.hex(16), communication_gateway: comm_gateway )
  org.phone_books.first.phone_book_entries.create!( phone_number_id: perf_phone_number.id, country: nil )

  org.stencils.create!({
    label: 'Performance Example',
    primary: true,
    phone_book_id: org.phone_books.first.id,
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
