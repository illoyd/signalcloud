##
# Represents a purchased telephone number which may be used in conversations. Additionally, these numbers are charged per
# month.
class PhoneNumber < ActiveRecord::Base

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

  attr_accessible :number, :twilio_phone_number_sid, :organization_id, :our_cost, :provider_cost, :unsolicited_sms_action, :unsolicited_sms_message, :unsolicited_call_action, :unsolicited_call_message, :unsolicited_call_language, :unsolicited_call_voice

  belongs_to :organization, inverse_of: :phone_numbers
  has_many :phone_book_entries, inverse_of: :phone_number, dependent: :destroy
  has_many :phone_books, through: :phone_book_entries
  has_many :unsolicited_calls, inverse_of: :phone_number
  has_many :unsolicited_messages, inverse_of: :phone_number

  ##
  # LedgerEntries for this message - usually one per month
  has_many :ledger_entries, as: :item

  validates_presence_of :organization, :twilio_phone_number_sid, :number
  validates_numericality_of :our_cost, :provider_cost, :organization_id

  validates_length_of :twilio_phone_number_sid, is: Twilio::SID_LENGTH
  validates_uniqueness_of :twilio_phone_number_sid, :case_sensitive => false

  validates :number, :phone_number => true
  
  validates_inclusion_of :unsolicited_sms_action, in: [ IGNORE, REPLY ]
  validates_presence_of :unsolicited_sms_message, if: :'should_reply_to_unsolicited_sms?'
  
  validates_inclusion_of :unsolicited_call_action, in: [ REJECT, BUSY, REPLY ]
  validates_presence_of :unsolicited_call_message, if: :'should_reply_to_unsolicited_call?'
  validates_presence_of :unsolicited_call_language, if: :'should_reply_to_unsolicited_call?'
  validates_presence_of :unsolicited_call_voice, if: :'should_reply_to_unsolicited_call?'
  validates_inclusion_of :unsolicited_call_language, allow_nil: true, in: LANGUAGES, if: :'should_reply_to_unsolicited_call?'
  validates_inclusion_of :unsolicited_call_voice, allow_nil: true, in: VOICES, if: :'should_reply_to_unsolicited_call?'
  
  before_validation :ensure_normalized_phone_number
  
  def human_number
    PhoneTools.humanize( self.number )
  end

  ##
  # Update provider cost and, by extension, our cost.
  def provider_cost=(value)
    super(value)
    self.our_cost = value.nil? ? nil : self.calculate_our_cost(value)
  end
  
  ##
  # Is a cost defined for this phone number?
  def has_cost?
    return !(self.our_cost.nil? or self.provider_cost.nil?)
  end
  
  ##
  # Cost of this phone number, combining provider and own charges
  def cost
    return (self.our_cost || 0) + (self.provider_cost || 0)
  end

  def purchase
    # If not assigned to an organization, cannot buy a number!
    raise OrganizationNotAssociatedError.new if self.organization.nil?
    results = self.organization.twilio_account.incoming_phone_numbers.create( { phone_number: self.number, application_sid: self.organization.twilio_application_sid } )
    self.twilio_phone_number_sid = results.sid
    return results
  end
  
  alias :buy :purchase
  
  def self.normalize_phone_number(pn)
    return pn.nil? ? nil : '+' + PhoneTools.normalize(pn)
  end
  
  def self.find_by_number(pn)
    raise ArgumentError.new( 'Given phone number was nil or blank.' ) if pn.blank?
    PhoneNumber.where( number: PhoneNumber.normalize_phone_number(pn) )
  end

  def number=(value)
    super( PhoneNumber.normalize_phone_number(value) )
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
    sms = self.organization.send_sms( customer_number, self.number, self.unsolicited_sms_message )
    #sms.stac
  end

  def calculate_our_cost( value=nil )
    return nil unless self.organization && self.organization.account_plan
    value = self.provider_cost if value.nil?
    return self.organization.account_plan.calculate_phone_number_cost( value )
  end
  
  def record_unsolicited_message( options={} )
  end

  # private  

  def ensure_normalized_phone_number
    self.number = PhoneNumber.normalize_phone_number(self.number)
  end
  
end
