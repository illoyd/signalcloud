require 'spec_helper'

describe Appliance do
  fixtures :account_plans, :accounts, :appliances, :tickets

  describe '.open_ticket' do
    
    it 'should create a new ticket' do
      appliance = appliances(:test_appliance)
      
      ticket = appliance.open_ticket( to_number: Twilio::VALID_NUMBER )
      ticket.save
      ticket.to_number.should == Phony::normalize( Twilio::VALID_NUMBER )
      
    end
    
  end  

end
