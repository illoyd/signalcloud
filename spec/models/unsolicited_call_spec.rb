require 'spec_helper'

describe UnsolicitedCall, :type => :model do

  skip 'need to revisit pricing' do
    it_behaves_like 'a priceable item', :unsolicited_call
  end

  describe 'validations' do
    [ :customer_number, :call_content, :received_at ].each do |attribute|
      it { is_expected.to validate_presence_of attribute }
    end
    
    # Disabled: does not support 0 as possible answer
    # it { should ensure_inclusion_of(:action_taken).in_array(PhoneNumber::CALL_ACTIONS) }
    # Resorting to testing each entry
    PhoneNumber::CALL_ACTIONS.each do |value|
      it { is_expected.to allow_value(value).for(:action_taken) }
    end
  end
  
end
