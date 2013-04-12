##
# Represents a purchased telephone number which may be used in tickets. Additionally, these numbers are charged per
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

  attr_accessible :number, :twilio_phone_number_sid, :account_id, :our_cost, :provider_cost, :unsolicited_sms_action, :unsolicited_sms_message, :unsolicited_call_action, :unsolicited_call_message, :unsolicited_call_language, :unsolicited_call_voice
  
  attr_encrypted :number, key: ATTR_ENCRYPTED_SECRET
  
  belongs_to :account, inverse_of: :phone_numbers
  has_many :phone_directory_entries, inverse_of: :phone_number
  has_many :phone_directories, through: :phone_directory_entries
  has_many :unsolicited_calls, inverse_of: :phone_number
  has_many :unsolicited_messages, inverse_of: :phone_number

  ##
  # LedgerEntries for this message - usually one per month
  has_many :ledger_entries, as: :item

  validates_presence_of :account_id, :twilio_phone_number_sid, :number
  validates_numericality_of :our_cost, :provider_cost, :account_id
  
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
    # If not assigned to an account, cannot buy a number!
    raise AccountNotAssociatedError.new if self.account.nil?
    results = self.account.twilio_account.incoming_phone_numbers.create( { phone_number: self.number, application_sid: self.account.twilio_application_sid } )
    self.twilio_phone_number_sid = results.sid
    return results
  end
  
  alias :buy :purchase
  
  def self.normalize_phone_number(pn)
    return pn.nil? ? nil : '+' + PhoneTools.normalize(pn)
  end
  
  def self.find_by_number(pn)
    PhoneNumber.where( encrypted_number: PhoneNumber.encrypt( :number, PhoneNumber.normalize_phone_number(pn) ) )
  end

  alias_method :'original_number=', :'number='
  def number=(value)
    self.original_number=( PhoneNumber.normalize_phone_number(value) )
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
    sms = self.account.send_sms( customer_number, self.number, self.unsolicited_sms_message )
    #sms.stac
  end

  def calculate_our_cost( value=nil )
    return nil unless self.account && self.account.account_plan
    value = self.provider_cost if value.nil?
    return self.account.account_plan.calculate_phone_number_cost( value )
  end
  
  def record_unsolicited_message( options={} )
  end

  # private  

  def ensure_normalized_phone_number
    self.number = PhoneNumber.normalize_phone_number(self.number)
  end
  
end
