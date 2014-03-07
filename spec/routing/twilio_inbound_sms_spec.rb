require 'spec_helper'

describe 'routing to twilio/inbound_sms' do
  #fixtures :organizations, :account_plans, :users

  it 'routes POST twilio/inbound_sms to twilio::inbound_sms#create' do
    expect( post('twilio/inbound_sms.xml') ).to route_to( controller: 'twilio/inbound_sms', action: 'create', format: 'xml' )
  end 
  
  it 'cannout route GET twilio/inbound_sms' do
    expect( get('twilio/inbound_sms.xml') ).to_not be_routable
  end

end
