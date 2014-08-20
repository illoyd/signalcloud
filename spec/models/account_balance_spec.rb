require 'spec_helper'

describe AccountBalance, :type => :model do

  describe 'validations' do
    subject { create(:organization).account_balance }

    [ :organization ].each do |attribute| 
      it { is_expected.to validate_presence_of attribute }
    end

    [ :balance ].each do |attribute| 
      it { pending 'Is this required? The balance resets if it is ever changed.'; is_expected.to validate_numericality_of attribute }
    end

  end

end
