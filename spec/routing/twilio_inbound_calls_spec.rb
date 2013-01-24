require 'spec_helper'

describe 'routing to twilio/inbound_call' do
  #fixtures :accounts, :account_plans, :users

  it 'routes POST twilio/inbound_call to twilio::inbound_call#create' do
    expect( post('twilio/inbound_call.xml') ).to route_to( controller: 'twilio/inbound_calls', action: 'create', format: 'xml' )
  end 
  
  it 'cannout route GET twilio/inbound_call' do
    expect( get('twilio/inbound_call.xml') ).to_not be_routable
  end

end
