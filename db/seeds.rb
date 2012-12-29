# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Add plan data
master_plan = AccountPlan.create label:'Super'
shared_plan = AccountPlan.create label:'Shared', month: 0, phone_add: 2, call_in_add: 0.02, sms_in_add: 0.02, sms_out_add: 0.02
dedicated_plan = AccountPlan.create label:'Dedicated', month: 500, phone_add: 1, call_in_add: 0.01, sms_in_add: 0.01, sms_out_add: 0.01

# Add master account (me!)
master_account = Account.new label:'Master Account', account_sid: 'master', auth_token: 'master', account_plan: master_plan, description: 'My master account'
  master_account.twilio_account_sid = ENV['TWILIO_MASTER_ACCOUNT_SID']
  master_account.twilio_auth_token = ENV['TWILIO_MASTER_AUTH_TOKEN']
  master_account.save!

test_account = Account.new label:'Test Account', account_sid: 'test', auth_token: 'test', account_plan: master_plan, description: 'My test account'
  test_account.twilio_account_sid = ENV['TWILIO_TEST_ACCOUNT_SID']
  test_account.twilio_auth_token = ENV['TWILIO_TEST_AUTH_TOKEN']
  test_account.save!

# Add users
test_user = test_account.users.create first_name: 'Jane', last_name: 'Doe', email: 'jane.doe@ticketpleaseapp.com', password: 'password', password_confirmation: 'password'

# Add example data for the test account
test_numbers = {
  US: test_account.phone_numbers.create( number: '+12125001234', twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) ),
  CA: test_account.phone_numbers.create( number: '+17127005678', twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) ),
  GB: test_account.phone_numbers.create( number: '+447540123456', twilio_phone_number_sid: 'XX'+SecureRandom.hex(16) )
}

example_directory = test_account.phone_directories.create label: 'Example Directory'
example_directory.phone_directory_entries.create phone_number_id: test_numbers[:US].id
test_numbers.each { |country,number| example_directory.phone_directory_entries.create country: country, phone_number_id: number.id }

example_appliance = test_account.appliances.create({ label: 'Example Appliance', default: true, phone_directory_id: example_directory.id, seconds_to_live: 180,
  description: 'Example appliance for handling possibly fraudulent charges to a debit card.',
  question: 'Hello from Friendly Bank. We recently detected a possibly fraudulent charge using your debit card. To protect you, we have temporarily blocked the card. If you are making this purchase and would like us to unlock the card, please reply to this number with the amount of the transaction. If you believe this charge is fraudulent, please reply NO and we will contact you about next steps.',
  expected_denied_answer: 'NO',
  confirmed_reply: 'Thank you. We will unblock your card immediately. Please retry your purchase.',
  denied_reply: 'Thank you. We will contact you shortly to discuss next steps to protect your account.',
  failed_reply: 'We are sorry, but your answer does not match your records. For your safety we have blocked your card and we will contact you shortly to discuss next steps.',
  expired_reply: 'We are sorry, but we did not receive your reply. For your safety we have blocked your card and we will contact you shortly to discuss next steps.'
  })

example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
example_appliance.open_ticket( to_number: '+' + (10000000000 + rand(9999999999)).to_s, expected_confirmed_answer: rand(100) + rand(99)/100 ).save!
