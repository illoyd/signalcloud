require 'spec_helper'

describe AccountBalance, :type => :model do

  describe 'validations' do

    [ :organization ].each do |attribute| 
      it { is_expected.to validate_presence_of attribute }
    end

    [ :balance ].each do |attribute| 
      it { is_expected.to validate_numericality_of attribute }
    end

  end

end
