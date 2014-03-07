class AccountPlan < ActiveRecord::Base
  extend Deprecations
  
  ARREARS = 1
  CREDIT = 0
  
  attr_accessor :phone_number_pricer, :conversation_pricer

  # Attributes
  # attr_accessible :plan_kind, :default, :call_in_add, :call_in_mult, :label, :month, :phone_add, :phone_mult, :sms_in_add, :sms_in_mult, :sms_out_add, :sms_out_mult
  
  # Relationships
  has_many :organizations, inverse_of: :account_plan
  
  # Validations
  validates_inclusion_of :plan_kind, in: [ ARREARS, CREDIT ]
  validates :phone_add,  :call_in_add,  :sms_in_add,  :sms_out_add,  numericality: { allow_nil: true, less_than_or_equal_to: 0.0 }
  validates :phone_mult, :call_in_mult, :sms_in_mult, :sms_out_mult, numericality: { allow_nil: true, greater_than_or_equal_to: -1.0 }

  ##
  # Return the account plan used for new organisations.  
  def self.default
    where( default: true ).first
  end
  
  def phone_number_pricer
    @phone_number_pricer ||= PhoneNumberPricer.new
  end
  
  def conversation_pricer
    @conversation_pricer ||= ConversationPricer.new
  end
  
  def price_for(obj)
    case
      when obj.is_a?(PhoneNumber)
        self.phone_number_pricer.price_for(obj)
      when obj.is_a?(Conversation)
        self.conversation_pricer.price_for(obj)
      else
        raise SignalCloud::UnpriceableObjectError.new(obj)
    end
  end
  
  ##
  # Calculate the cost of a phone number, based on the cost from the provider
  def calculate_phone_number_cost( provider_cost )
    return self.phone_add + self.phone_mult * provider_cost
  end
  
  alias :calculate_phone_number_price :calculate_phone_number_cost
  deprecated :calculate_phone_number_cost
  
  ##
  # Calculate the cost of an inbound SMS, based on the cost from the provider
  def calculate_inbound_sms_cost( provider_cost )
    return self.sms_in_add + self.sms_in_mult * provider_cost
  end

  alias :calculate_inbound_sms_price :calculate_inbound_sms_cost
  deprecated :calculate_inbound_sms_cost
  
  ##
  # Calculate the cost of an outbound SMS, based on the cost from the provider
  def calculate_outbound_sms_cost( provider_cost )
    return self.sms_out_add + self.sms_out_mult * provider_cost
  end
  
  alias :calculate_outbound_sms_price :calculate_outbound_sms_cost
  deprecated :calculate_outbound_sms_cost
  
  ##
  # Calculate the cost of an inbound phone call, based on the cost from the provider
  def calculate_inbound_call_cost( provider_cost )
    return self.call_in_add + self.call_in_mult * provider_cost
  end
  
  alias :calculate_inbound_call_price :calculate_inbound_call_cost
  deprecated :calculate_inbound_call_cost
  
  ##
  # Is this plan payable in arrears?
  def is_payable_in_arrears?
    return self.plan_kind == ARREARS
  end

end
