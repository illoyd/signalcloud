require 'spec_helper'

describe UnsolicitedCall do

  it_behaves_like 'a priceable item', :unsolicited_call

  describe 'validations' do
    [ :twilio_call_sid, :action_content, :action_taken, :action_taken_at, :customer_number, :call_content, :received_at ].each do |attribute|
      it { should allow_mass_assignment_of attribute }
    end
    
    [ :customer_number, :call_content, :received_at ].each do |attribute|
      it { should validate_presence_of attribute }
    end
    
    # Disabled: does not support 0 as possible answer
    # it { should ensure_inclusion_of(:action_taken).in_array(PhoneNumber::CALL_ACTIONS) }
    # Resorting to testing each entry
    PhoneNumber::CALL_ACTIONS.each do |value|
      it { should allow_value(value).for(:action_taken) }
    end
  end
  
end
