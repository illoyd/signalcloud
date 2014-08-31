class Stencil < ActiveRecord::Base

  # Encrypted attributes
  attr_encrypted_options.merge!(key: Rails.application.secrets.encrypted_secret, mode: :per_attribute_iv_and_salt)
  attr_encrypted :confirmed_reply
  attr_encrypted :denied_reply
  attr_encrypted :expired_reply
  attr_encrypted :failed_reply
  attr_encrypted :question
  attr_encrypted :expected_confirmed_answer
  attr_encrypted :expected_denied_answer
  attr_encrypted :webhook_uri
  
  # Relationships
  belongs_to :organization, inverse_of: :stencils
  belongs_to :phone_book, inverse_of: :stencils
  has_many :conversations, inverse_of: :stencil, dependent: :restrict_with_error
  
  # Validations
  validates_presence_of :organization, :label
  validates :webhook_uri, http_url: true, allow_blank: true
  
  # Scopes
  scope :active,   ->{ where( :active => true ) }
  scope :inactive, ->{ where( :active => false ) }
  
  # Normalizations
  normalize_attributes :label, :description, :question, :expected_confirmed_answer, :expected_denied_answer, :confirmed_reply, :denied_reply, :failed_reply, :expired_reply, :webhook_uri
  
  ##
  # Parameters passed to newly built conversations
  CONVERSATION_PARAMETERS = [ :seconds_to_live, :question, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :confirmed_reply, :denied_reply ]

  def build_conversation( passed_options={} )
    # Build a hash of options using self as a default, merging passed options
    options = CONVERSATION_PARAMETERS.each_with_object({}) { |key,h| h[key] = send(key) }
    options = options.with_indifferent_access.merge( passed_options.with_indifferent_access )
    
    # Add a randomly selected from number if needed
    if options[:internal_number_id].blank? and options[:customer_number].present?
      options[:internal_number] = self.phone_book.select_internal_number_for( options[:customer_number] )
    end
    return self.conversations.build( options )
  end
  alias_method :open_conversation, :build_conversation
  
end
