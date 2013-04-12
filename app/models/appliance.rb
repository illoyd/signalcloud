class Appliance < ActiveRecord::Base
  # Attributes
  #attr_accessible :encrypted_confirmed_reply, :encrypted_denied_reply, :encrypted_expected_confirmed_answer, :encrypted_expected_denied_answer, :encrypted_expired_reply, :encrypted_failed_reply, :encrypted_question, :phone_directory, :seconds_to_live
  attr_accessible :label, :primary, :phone_directory_id, :seconds_to_live, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :question, :description, :webhook_uri
  
  # Encrypted attributes
  attr_encrypted :confirmed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :question, key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :expected_confirmed_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_denied_answer, key: ATTR_ENCRYPTED_SECRET
  
  # Relationships
  belongs_to :account, inverse_of: :appliances
  belongs_to :phone_directory, inverse_of: :appliances
  has_many :tickets, inverse_of: :appliance
  
  def open_ticket( passed_options )
    # Build a hash of options using self as a default, merging passed options
    options = {
      seconds_to_live: self.seconds_to_live,
      question: self.question,
      expected_confirmed_answer: self.expected_confirmed_answer,
      expected_denied_answer: self.expected_denied_answer,
      expired_reply: self.expired_reply,
      failed_reply: self.failed_reply,
      confirmed_reply: self.confirmed_reply,
      denied_reply: self.denied_reply
    }.with_indifferent_access.merge( passed_options.with_indifferent_access )
    
    # Add a randomly selected from number if needed
    options[:from_number] = self.phone_directory.select_from_number( options[:to_number] ).number unless options.key? :from_number
    return self.tickets.build( options )
  end
end
