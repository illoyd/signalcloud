class Stencil < ActiveRecord::Base

  # Encrypted attributes
  attr_encrypted :confirmed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :question, key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :expected_confirmed_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_denied_answer, key: ATTR_ENCRYPTED_SECRET
  
  # Relationships
  belongs_to :organization, inverse_of: :stencils
  belongs_to :phone_book, inverse_of: :stencils
  has_many :conversations, inverse_of: :stencil
  
  validates_presence_of :organization
  
  # Scopes
  scope :active,   where( :active => true )
  scope :inactive, where( :active => false )

  def open_conversation( passed_options )
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
    options[:from_number] = self.phone_book.select_internal_number_for( options[:to_number] ).number if options.fetch(:from_number, nil).nil?
    return self.conversations.build( options )
  end
end
