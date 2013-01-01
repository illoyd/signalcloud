require 'spec_helper'

describe User do
  fixtures :users, :accounts
  
  # Validations
  it { [ :account, :first_name, :last_name, :roles, :email, :password, :password_confirmation, :remember_me ].each { |param| should allow_mass_assignment_of(param) } }
  it { [ :account_id, :first_name, :last_name, :email, :password ].each { |param| should validate_presence_of(param) } }
  it { should belong_to(:account) }
  
  # Roles and bitmask
  describe '.roles' do

    it 'should add shadow_account flag (as an example)' do
      user = users(:payg_user)
      user.roles.empty?.should == true
      user.can_shadow_account?.should == false

      user.roles = [ :shadow_account ]

      user.roles.empty?.should == false
      user.roles.should eq( [:shadow_account] )
      user.can_shadow_account?.should == true
    end

    it 'should check all flags' do
      user = users(:payg_user)
      user.roles.empty?.should == true
      
      User::ROLES.shuffle.each do |role|
        user.roles = [role]
        user.roles.empty?.should == false
        user.roles.should eq([role])
      end
    end

    it 'should check all combinations of roles' do
      user = users(:payg_user)
      user.roles.empty?.should == true
      
      # Combine all roles (will create an array of arrays)
      role_sets = []
      (0..(User::ROLES.size)).each { |x| role_sets += User::ROLES.permutation(x).to_a }
      
      # Check every role set
      role_sets.each do |role_set|
        user.roles = role_set
        user.roles.empty?.should == role_set.empty?
        user.roles.sort.should eq(role_set.sort)
      end

    end

  end
  
  describe '.can_*?' do

    it 'should check all combinations of roles' do
      user = users(:payg_user)
      user.roles.empty?.should == true
      
      # Build all possible combinations of roles (this returns an array of arrays)
      roles = []
      (0..(User::ROLES.size)).each { |x| roles += User::ROLES.combination(x).to_a }
      
      roles.each do |role|
        user.roles = role
        role.each { |entry| user.send("can_#{entry}?".to_sym).should == true }
        (User::ROLES - role).each { |entry| user.send("can_#{entry}?".to_sym).should == false }
      end

    end

  end

end
