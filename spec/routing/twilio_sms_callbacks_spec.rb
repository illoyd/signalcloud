require 'spec_helper'

describe 'routing to twilio/sms_callback' do
  #fixtures :accounts, :account_plans, :users

  it 'routes POST twilio/sms_callback to twilio::sms_callback#create' do
    expect( post('twilio/sms_callback.xml') ).to route_to( controller: 'twilio/sms_callbacks', action: 'create', format: 'xml' )
  end 
  
  it 'cannout route GET twilio/sms_callback' do
    expect( get('twilio/sms_callback.xml') ).to_not be_routable
  end

end
