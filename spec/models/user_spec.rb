require 'spec_helper'

describe User do
  
  def role_combinations
    roles = []
    (0..(User::ROLES.size)).each { |x| roles += User::ROLES.combination(x).to_a }
    return roles
  end

  describe 'validations' do  
    [ :account, :first_name, :last_name, :roles, :email, :password, :password_confirmation, :remember_me ].each do |attribute| 
      it { should allow_mass_assignment_of(attribute) }
    end

    [ :account_id, :first_name, :last_name, :email, :password ].each do |attribute| 
      it { should validate_presence_of(attribute) }
    end

    it { should belong_to(:account) }
  end
  
  # Roles and bitmask
  describe '#roles' do
  
    it 'checks all combinations of roles' do
      user = create(:user)
      user.roles.empty?.should == true
      
      # Check every role set
      role_combinations().each do |role_set|
        user.roles = role_set
        
        # Test entire role set
        user.roles.sort.should eq(role_set.sort)
        
        # Test all positive roles via the is_*? function
        role_set.each { |role| user.send("is_#{role}?".to_sym).should == true }

        # Test all negative roles via the is_*? function
        (User::ROLES - role_set).each { |role| user.send("is_#{role}?".to_sym).should == false }
      end

    end

  end
  
end
