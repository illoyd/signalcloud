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
my_account = Account.create label:'Master Account', account_sid: 'master', auth_token: 'master', account_plan: master_plan, twilio_account_sid: ENV['TWILIO_MASTER_ACCOUNT_SID'], twilio_auth_token: ENV['TWILIO_MASTER_AUTH_TOKEN']
test_account = Account.create label:'Test Account', account_sid: 'test', auth_token: 'test', account_plan: master_plan, twilio_account_sid: ENV['TWILIO_TEST_ACCOUNT'], twilio_auth_token: ENV['TWILIO_TEST_AUTH_TOKEN']

# 
