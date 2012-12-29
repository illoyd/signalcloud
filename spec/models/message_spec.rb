require 'spec_helper'

describe Message do

  # Validations
  it { [ :our_cost, :provider_cost, :ticket_id, :payload, :twilio_sid ].each { |param| should allow_mass_assignment_of(param) } }
  it { should belong_to(:ticket) }
  it { should validate_presence_of(:ticket_id) }
  it { should validate_length_of(:twilio_sid).is_equal_to(TWILIO_SID_LENGTH) }
  it { should validate_uniqueness_of(:twilio_sid) }
  it { should validate_numericality_of(:our_cost) }
  it { should validate_numericality_of(:provider_cost) }
  
  describe ".payload" do
    
  end
  
end
