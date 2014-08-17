require 'spec_helper'

describe User, :type => :model do
  
  describe 'validations' do  
    [ :email, :password ].each do |attribute| 
      it { is_expected.to validate_presence_of(attribute) }
    end

    it { is_expected.to have_many(:user_roles) }
    it { is_expected.to have_many(:organizations) }
  end
  
end
