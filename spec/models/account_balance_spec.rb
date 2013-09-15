require 'spec_helper'

describe AccountBalance do

  describe 'validations' do

    [ :organization ].each do |attribute| 
      it { should validate_presence_of attribute }
    end

    [ :balance ].each do |attribute| 
      it { should validate_numericality_of attribute }
    end

  end

end
