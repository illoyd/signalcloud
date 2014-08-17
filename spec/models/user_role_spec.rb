require 'spec_helper'

def role_combinations
  roles = []
  (0..(UserRole::ROLES.size)).each { |x| roles += UserRole::ROLES.combination(x).to_a }
  return roles
end

describe UserRole, :type => :model do

  describe 'validations' do  
    [ :organization, :user, :roles_mask ].each do |attribute| 
      it { is_expected.to validate_presence_of(attribute) }
    end

    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:user) }
  end
  
  # Roles and bitmask
  describe '#roles' do
  
    # Check every role set
    (role_combinations).each do |role_set|
    
      describe (role_set.sort.to_s) do
        subject { UserRole.new roles: role_set.shuffle }

        describe '#roles' do
          subject { super().roles }
          describe '#sort' do
            subject { super().sort }
            it { is_expected.to eq(role_set.sort) }
          end
        end
        
        role_set.each do |role|
          describe "is_#{role}?" do
            subject { super().send("is_#{role}?") }
            it { is_expected.to be_truthy }
          end
        end
        
        (UserRole::ROLES - role_set).each do |role|
          describe "is_#{role}?" do
            subject { super().send("is_#{role}?") }
            it { is_expected.to be_falsey }
          end
        end
        
      end
  
    end

  end

end
