require 'spec_helper'

describe Address do

  it { should belong_to :account }

  [ :first_name, :last_name, :email, :city, :region, :postcode, :country ].each do |attribute|
    it { should validate_presence_of attribute }
  end
  
  [ :first_name, :last_name, :email, :work_phone, :line1, :line2, :city, :region, :postcode, :country, :account_id ].each do |attribute|
    it { should allow_mass_assignment_of attribute }
  end
  
end