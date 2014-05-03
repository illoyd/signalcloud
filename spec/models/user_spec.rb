require 'spec_helper'

describe User do
  
  describe 'validations' do  
    [ :email, :password ].each do |attribute| 
      it { should validate_presence_of(attribute) }
    end

    it { should have_many(:user_roles) }
    it { should have_many(:organizations) }
  end
  
end
