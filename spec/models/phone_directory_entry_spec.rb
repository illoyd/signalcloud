require 'spec_helper'

describe PhoneDirectoryEntry do

  it { should belong_to :phone_directory }
  it { should belong_to :phone_number }

  [ :phone_directory, :phone_number ].each do |attribute|
    it { should validate_presence_of attribute }
  end
  
  [ :country, :phone_number_id, :phone_directory_id ].each do |attribute|
    it { should allow_mass_assignment_of attribute }
  end
  
  it { should ensure_inclusion_of(:country).in_array(PhoneDirectoryEntry::COUNTRIES) }
  
end
