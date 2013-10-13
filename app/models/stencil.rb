class Stencil < ActiveRecord::Base

  # Encrypted attributes
  attr_encrypted :confirmed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :denied_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expired_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :failed_reply, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :question, key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :expected_confirmed_answer, key: ATTR_ENCRYPTED_SECRET
  attr_encrypted :expected_denied_answer, key: ATTR_ENCRYPTED_SECRET

  attr_encrypted :webhook_uri, key: ATTR_ENCRYPTED_SECRET
  
  # Relationships
  belongs_to :organization, inverse_of: :stencils
  belongs_to :phone_book, inverse_of: :stencils
  has_many :conversations, inverse_of: :stencil
  
  validates_presence_of :organization, :label
  
  # Scopes
  scope :active,   where( :active => true )
  scope :inactive, where( :active => false )
  
  ##
  # Parameters passed to newly built conversations
  CONVERSATION_PARAMETERS = [ :seconds_to_live, :question, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :confirmed_reply, :denied_reply ]

  def build_conversation( passed_options={} )
    # Build a hash of options using self as a default, merging passed options
    options = CONVERSATION_PARAMETERS.each_with_object({}) { |key,h| h[key] = send(key) }
    options = options.with_indifferent_access.merge( passed_options.with_indifferent_access )
    options[:parameters] = options.fetch(:parameters,{}).merge( self.defined_parameters_hash )
    
    # Add a randomly selected from number if needed
    if options.fetch(:internal_number, nil).blank? and !options.fetch(:customer_number, nil).blank?
      options[:internal_number] = self.phone_book.select_internal_number_for( options[:customer_number] ).number
    end
    
    # Finally, build the stupid conversation and return it
    self.conversations.build( options )
  end
  alias_method :open_conversation, :build_conversation
  
  def defined_parameters
    (
      find_parameters( self.question ) +
      find_parameters( self.expected_confirmed_answer ) +
      find_parameters( self.expected_denied_answer ) +
      find_parameters( self.confirmed_reply ) +
      find_parameters( self.denied_reply ) +
      find_parameters( self.failed_reply ) +
      find_parameters( self.expired_reply )
    ).flatten.uniq
  end
  
  def defined_parameters_hash
    self.defined_parameters.each_with_object({}) { |key,h| h[key] = '' }
  end
  
protected

  def find_parameters( text )
    text.scan(/\{\{\s*(.+?)\s*\}\}/i).flatten
  end

end
