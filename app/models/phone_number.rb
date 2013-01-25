##
# Represents a purchased telephone number which may be used in tickets. Additionally, these numbers are charged per
# month.
class PhoneNumber < ActiveRecord::Base

  IGNORE = 3
  REJECT = 0
  BUSY = 1
  REPLY = 2
  
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
  
  before_save :normalize_phone_number

  def cost
    return ( self.provider_cost || 0 ) + ( self.our_cost || 0 )
  end

  def buy
    # If not assigned to an account, cannot buy a number!
    raise TicketpleaseError.new( 'PhoneNumber not associated to an Account' ) if self.account.nil?
    results = self.account.twilio_account.incoming_phone_numbers.create( { phone_number: self.number, application_sid: self.account.twilio_application_sid } )
    self.twilio_phone_number_sid = results.sid
    return results
  end

  def normalize_phone_number
    self.number = Phony.normalize self.number
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

end
