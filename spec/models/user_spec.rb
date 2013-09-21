require 'spec_helper'

describe User do
  
  describe 'validations' do  
    [ :first_name, :last_name, :email, :password, :password_confirmation, :remember_me ].each do |attribute| 
      it { should allow_mass_assignment_of(attribute) }
    end

    [ :email, :password ].each do |attribute| 
      it { should validate_presence_of(attribute) }
    end

    it { should have_many(:user_roles) }
    it { should have_many(:organizations) }
  end
  
end
