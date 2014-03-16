require 'spec_helper'

def role_combinations
  roles = []
  (0..(UserRole::ROLES.size)).each { |x| roles += UserRole::ROLES.combination(x).to_a }
  return roles
end

describe UserRole do

  describe 'validations' do  
    [ :organization, :user, :roles_mask ].each do |attribute| 
      it { should validate_presence_of(attribute) }
    end

    it { should belong_to(:organization) }
    it { should belong_to(:user) }
  end
  
  # Roles and bitmask
  describe '#roles' do
  
    # Check every role set
    (role_combinations).each do |role_set|
    
      describe (role_set.sort.to_s) do
        subject { UserRole.new roles: role_set.shuffle }

        its('roles.sort') { should == role_set.sort }
        
        role_set.each do |role|
          its("is_#{role}?") { should be_true }
        end
        
        (UserRole::ROLES - role_set).each do |role|
          its("is_#{role}?") { should be_false }
        end
        
      end
  
    end

  end

end
