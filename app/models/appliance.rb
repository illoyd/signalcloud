class Appliance < ActiveRecord::Base
  # Attributes
  #attr_accessible :encrypted_confirmed_reply, :encrypted_denied_reply, :encrypted_expected_confirmed_answer, :encrypted_expected_denied_answer, :encrypted_expired_reply, :encrypted_failed_reply, :encrypted_question, :phone_directory, :seconds_to_live
  attr_accessible :label, :phone_directory_id, :seconds_to_live, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :question
  
  # Encrypted attributes
  attr_encrypted :confirmed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_confirmed_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_denied_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :question, key: ATTR_ENCRYPTED_SECRET
  
  # Relationships
  belongs_to :account, inverse_of: :appliances
  belongs_to :phone_directory, inverse_of: :appliances
  has_many :tickets, inverse_of: :appliance
end
