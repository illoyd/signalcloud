require 'spec_helper'

describe 'routing to twilio/sms_update' do

  it 'routes POST twilio/sms_update to twilio::sms_callback#create' do
    expect( post('twilio/sms_update.xml') ).to route_to( controller: 'twilio/sms_updates', action: 'create', format: 'xml' )
  end 
  
  it 'cannout route GET twilio/sms_update' do
    expect( get('twilio/sms_update.xml') ).not_to be_routable
  end

end
