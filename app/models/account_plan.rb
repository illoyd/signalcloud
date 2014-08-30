class AccountPlan < ActiveRecord::Base
  extend Deprecations
  
  ARREARS = 1
  CREDIT = 0
  
  # Attributes
  serialize :phone_number_pricer_config, HashWithIndifferentAccess
  serialize :conversation_pricer_config, HashWithIndifferentAccess

  # Relationships
  has_many :organizations, inverse_of: :account_plan
  
  # Validations
  validates_inclusion_of :plan_kind, in: [ ARREARS, CREDIT ]
  validates :month,  numericality: { allow_nil: true, greater_than_or_equal_to: 0.0 }
  #validates :phone_add,  :call_in_add,  :sms_in_add,  :sms_out_add,  numericality: { allow_nil: true, less_than_or_equal_to: 0.0 }
  #validates :phone_mult, :call_in_mult, :sms_in_mult, :sms_out_mult, numericality: { allow_nil: true, greater_than_or_equal_to: -1.0 }

  ##
  # Return the account plan used for new organisations.  
  def self.default
    where( default: true ).first
  end
  
  ##
  # Get the currenly configured phone number pricer.
  def phone_number_pricer
    @phone_number_pricer ||= phone_number_pricer_class.constantize.new(phone_number_pricer_config)
  end
  
  ##
  # Get the currenly configured conversation pricer.
  def conversation_pricer
    @conversation_pricer ||= conversation_pricer_class.constantize.new(conversation_pricer_config)
  end
  
  ##
  # Determine price for an object. Delegates to the appropriate pricer tool.
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
  # Is this plan payable in arrears?
  def is_payable_in_arrears?
    return self.plan_kind == ARREARS
  end

end
