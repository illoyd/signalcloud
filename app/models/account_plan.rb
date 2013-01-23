class AccountPlan < ActiveRecord::Base
  ARREARS = 1
  CREDIT = 0

  # Attributes
  attr_accessible :plan_kind, :default, :call_in_add, :call_in_mult, :label, :month, :phone_add, :phone_mult, :sms_in_add, :sms_in_mult, :sms_out_add, :sms_out_mult
  
  # Relationships
  has_many :accounts, inverse_of: :account_plan
  
  # Validations
  validates_inclusion_of :plan_kind, in: [ ARREARS, CREDIT ]
  
  ##
  # Calculate the cost of a phone number, based on the cost from the provider
  def calculate_phone_number_cost( provider_cost )
    return self.phone_add + self.phone_mult * provider_cost
  end
  
  ##
  # Calculate the cost of an inbound SMS, based on the cost from the provider
  def calculate_inbound_sms_cost( provider_cost )
    return self.sms_in_add + self.sms_in_mult * provider_cost
  end

  ##
  # Calculate the cost of an outbound SMS, based on the cost from the provider
  def calculate_outbound_sms_cost( provider_cost )
    return self.sms_out_add + self.sms_out_mult * provider_cost
  end
  
  ##
  # Calculate the cost of an inbound phone call, based on the cost from the provider
  def calculate_inbound_call_cost( provider_cost )
    return self.call_in_add + self.call_in_mult * provider_cost
  end
  
  ##
  # Is this plan payable in arrears?
  def is_payable_in_arrears?
    return self.plan_kind == ARREARS
  end

end
