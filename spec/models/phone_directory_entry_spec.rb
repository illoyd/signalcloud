require 'spec_helper'

describe PhoneBookEntry do

  it { should belong_to :phone_book }
  it { should belong_to :phone_number }

  [ :phone_book, :phone_number ].each do |attribute|
    it { should validate_presence_of attribute }
  end
  
  [ :country, :phone_number_id, :phone_book_id ].each do |attribute|
    it { should allow_mass_assignment_of attribute }
  end
  
  it { should ensure_inclusion_of(:country).in_array(PhoneBookEntry::COUNTRIES) }
  
end
