class PhoneNumber < ActiveRecord::Base
  belongs_to :team, inverse_of: :phone_numbers
  
  normalize_attributes :provider_sid, :description
  normalize_attribute :number, with: :phone_number
  
  include Workflow
  workflow do
    state :draft do
      event :purchase, transitions_to: :active
    end
    state :active do
      event :release, transitions_to: :inactive
    end
    state :inactive do
      event :purchase, transitions_to: :active
    end
  end
  
  protected
  
  def purchase
  end
  
  def release
  end

end
