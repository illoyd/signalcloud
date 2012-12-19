class AccountPlan < ActiveRecord::Base
  # Attributes
  attr_accessible :default, :call_in_add, :call_in_mult, :label, :month, :phone_add, :phone_mult, :sms_in_add, :sms_in_mult, :sms_out_add, :sms_out_mult
  
  # Relationships
  has_many :accounts, inverse_of: :account_plan
end
