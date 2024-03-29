##
# Represents a purchased telephone number which may be used in conversations. Additionally, these numbers are charged per
# month.
class PhoneNumber < ActiveRecord::Base
  include Workflow

  workflow do
    state :inactive do
      event :purchase, transitions_to: :active
    end
    state :active do
      event :release, transitions_to: :inactive
      event :refresh, transitions_to: :active
    end
  end

  alias_method :buy!, :purchase!
  alias_method :unbuy!, :release!
  alias_method :unpurchase!, :release!
  
  IGNORE = 0
  REJECT = 0
  BUSY = 1
  REPLY = 2
  CALL_ACTIONS = [ REJECT, BUSY, REPLY ]
  MESSAGE_ACTIONS = [ IGNORE, REPLY ]
  
  WOMAN_VOICE = 'woman'
  MAN_VOICE = 'man'
  
  VOICES = [ WOMAN_VOICE, MAN_VOICE ]
  
  AMERICAN_ENGLISH = 'en'
  BRITISH_ENGLISH = 'en-gb'
  SPANISH = 'es'
  FRENCH = 'fr'
  GERMAN = 'de'
  ITALIAN = 'it'
  LANGUAGES = [ AMERICAN_ENGLISH, BRITISH_ENGLISH, SPANISH, FRENCH, GERMAN, ITALIAN ]

  belongs_to :organization, inverse_of: :phone_numbers
  has_many :phone_book_entries, inverse_of: :phone_number, dependent: :destroy
  has_many :phone_books, through: :phone_book_entries
  has_many :conversations, inverse_of: :internal_number
  has_many :unsolicited_calls, inverse_of: :phone_number
  has_many :unsolicited_messages, inverse_of: :phone_number
  belongs_to :communication_gateway, inverse_of: :phone_numbers

  ##
  # LedgerEntries for this message - usually one per month
  has_many :ledger_entries, as: :item

  validates_presence_of :organization, :communication_gateway, :number
  validates_numericality_of :cost

  validates :number, :phone_number => true
  
  validates_inclusion_of :unsolicited_sms_action, in: [ IGNORE, REPLY ]
  validates_presence_of :unsolicited_sms_message, if: :'should_reply_to_unsolicited_sms?'
  
  validates_inclusion_of :unsolicited_call_action, in: [ REJECT, BUSY, REPLY ]
  validates_presence_of :unsolicited_call_message, if: :'should_reply_to_unsolicited_call?'
  validates_presence_of :unsolicited_call_language, if: :'should_reply_to_unsolicited_call?'
  validates_presence_of :unsolicited_call_voice, if: :'should_reply_to_unsolicited_call?'
  validates_inclusion_of :unsolicited_call_language, allow_nil: true, in: LANGUAGES, if: :'should_reply_to_unsolicited_call?'
  validates_inclusion_of :unsolicited_call_voice, allow_nil: true, in: VOICES, if: :'should_reply_to_unsolicited_call?'
  
#   before_validation :ensure_normalized_phone_number
  
  normalize_attributes :unsolicited_sms_message, :unsolicited_call_message
  normalize_attribute :number, with: :phone_number
  
  serialize :number, MiniPhoneNumber
  delegate :country, :alpha2, to: :number
  
  def human_number
    Country.format_international_phone_number(number.to_s)
  end
  
  def self.normalize_phone_number(pn)
    pn = pn.phone_number if pn.is_a?(MiniPhoneNumber)
    return pn.nil? ? nil : PhoneNumberNormalizer.normalize(pn)
  end
  
  def self.find_by_number(pn)
    raise ArgumentError.new( 'Given phone number was nil or blank.' ) if pn.blank?
    PhoneNumber.find_by( number: PhoneNumberNormalizer.normalize(pn) )
  end

  def should_ignore_unsolicited_sms?
    self.unsolicited_sms_action == IGNORE
  end
  
  def should_reply_to_unsolicited_sms?
    self.unsolicited_sms_action == REPLY
  end

  def should_reject_unsolicited_call?
    self.unsolicited_call_action == REJECT
  end
  
  def should_play_busy_for_unsolicited_call?
    self.unsolicited_call_action == BUSY
  end
  
  def should_reply_to_unsolicited_call?
    self.unsolicited_call_action == REPLY
  end
  
  def send_reply_to_unsolicited_sms( customer_number )
    # sms = self.communication_gateway.send_sms!( customer_number, self.number, self.unsolicited_sms_message )
    # sms.stac
  end

  def record_unsolicited_message( options={} )
  end

protected

  ##
  # Automagically normalise the number.
#   def ensure_normalized_phone_number
#     self.number = PhoneNumber.normalize_phone_number(self.number)
#   end
  
  ##
  # Attempt to buy the phone number from the Twilio API. If it receives an error, halt the operation.
  def purchase
    raise OrganizationNotAssociatedError.new if self.organization.nil?
    self.communication_gateway.purchase_number!( self )
  end

  ##
  # Using the phone number's Twilio SID, get an instance of it from Twilio's API then perform a 'DELETE' action against it.
  def release
    # If not assigned to an organization, cannot unbuy a number!
    raise OrganizationNotAssociatedError.new if self.organization.nil?
    self.communication_gateway.unpurchase_number! self
  end

  def refresh
    # If not assigned to an organization, cannot refresh a number!
    raise OrganizationNotAssociatedError.new if self.organization.nil?
    self.communication_gateway.update_number! self
    self.updated_remote_at = Time.now
  end

end
