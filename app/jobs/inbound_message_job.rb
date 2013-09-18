##
# Handle inbound SMS messages by finding the associated conversation and processing.
# Requires the following items
#   +provider_update+: all values as passed by the callback
#   +quiet+: a flag to indicate if this job should report itself on STDOUT
#
# Generally +provider_update+ will include the following:
#   +SmsSid+:     A 34 character unique identifier for the message. May be used to later retrieve this message from the REST API.
#   +AccountSid+: The 34 character id of the Organization this message is associated with.
#   +To+:         The phone number of the recipient.
#   +From+:       The phone number that sent this message.
#   +Body+:       The text body of the SMS message. Up to 160 characters long.
#
# The #normalize_provider_update command will normalise the values to 'underscored' names. For example, +SmsSid+ will become +sms_sid+.
#
# This class is intended for use with Sidekiq.
#
class InboundMessageJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform( provider_update )
    # self.normalize_provider_update!
    @sms ||= Twilio::InboundSms.new( self.provider_update )
    
    # Find all open conversations
    open_conversations = self.find_open_conversations()
    
    case open_conversations.count
      # No open conversations found; treat as an unsolicited message.
      when 0
        self.perform_unsolicited_action()
      
      # Only one conversation, so process immediately
      when 1
        self.perform_matching_conversation_action(open_conversations.first )

      # More than 1, so scan for possible positive or negative match.
      else
        self.perform_multiple_matching_conversations_action(open_conversations )
    end
  end
  
  def perform_unsolicited_action()
    #self.internal_phone_number.record_unsolicited_message({
    #  customer_number: self.provider_update[:from],
    #  body: self.provider_update[:body],
    #  payload: self.provider_update
    #})

    unsolicited_message = self.internal_phone_number.unsolicited_messages.build( twilio_sms_sid: @sms.sms_sid, customer_number: @sms.from, received_at: DateTime.now, message_content: self.provider_update )
    
    if self.internal_phone_number().should_reply_to_unsolicited_sms?
      unsolicited_message.action_taken = PhoneNumber::REPLY
      unsolicited_message.deliver_reply!
      # JobTools.enqueue SendUnsolicitedMessageReplyJob.new( self.internal_phone_number.id, self.provider_update[:from] )
    else
      unsolicited_message.action_taken = PhoneNumber::IGNORE
    end

    unsolicited_message.save
  end
  
  def perform_matching_conversation_action( conversation )
    message = conversation.messages.build( twilio_sid: @sms.sms_sid, from_number: @sms.from, to_number: @sms.to, body: @sms.body, direction: Message::DIRECTION_IN, provider_response: self.provider_update )
    message.refresh_from_twilio!

    conversation.accept_answer! @sms.body
    SendConversationReplyJob.perform_async(conversation.id)
    SendConversationStatusWebhookJob.perform_async( conversation.id, ConversationSerializer.new(conversation).as_json ) unless conversation.webhook_uri.blank?
  end
  
  def perform_multiple_matching_conversations_action( open_conversations )
    matching_conversation = open_conversations.first

    # Scan for possible applicable conversations
    open_conversations.each do |conversation|
      # If one is found, process it immediately and stop
      if conversation.answer_applies? @sms.body
        matching_conversation = conversation
        break
      end
    end
    
    # Perform the 'normal' action
    self.perform_matching_conversation_action( matching_conversation )
  end
  
  ##
  # Process conversation!
#   def process_conversation( conversation )
#     conversation.process_answer! self.provider_update[:body]
#     JobTools.enqueue SendConversationReplyJob.new conversation.id
#     # TODO JobTools.enqueue SendConversationStatusWebhookJob.new conversation.id
#   end

  ##  
  # Intuit the appropriate conversation based upon the TO and FROM.
  # In this situation, we SWAP the given TO and FROM, as this is a reply from the user. Conversations are always from: SignalCloud, to: the recepient.
  def find_open_conversations()
    @sms ||= Twilio::InboundSms.new( self.provider_update )
    # self.normalize_provider_update!
    Conversation.find_open_conversations( @sms.to, @sms.from ).order( 'challenge_sent_at' )
#     normalized_to_number = PhoneNumber.normalize_phone_number self.provider_update[:to]
#     normalized_from_number = PhoneNumber.normalize_phone_number self.provider_update[:from]
#     Conversation.where({
#       encrypted_to_number: Conversation.encrypt( :to_number, normalized_from_number ),
#       encrypted_from_number: Conversation.encrypt( :from_number, normalized_to_number ),
#       status: Conversation::CHALLENGE_SENT
#       }).order('challenge_sent_at')
  end
  
#   def handle_response_to_conversation()
#     conversation = self.find_open_conversations.first
#     self.add_message_to_conversation(conversation)
#     self.update_conversation(conversation)
#     conversation.send_reply_message!()
#   end

#   def is_unsolicited_message?
#     self.find_open_conversations.empty?
#   end
  
  def internal_phone_number()
    @sms ||= Twilio::InboundSms.new( self.provider_update )
    #self.normalize_provider_update!
    #normalized_to_number = PhoneNumber.normalize_phone_number self.provider_update[:to]
    #@phone_number ||= PhoneNumber.where( encrypted_number: PhoneNumber.encrypt( :number, normalized_to_number ) ).first
    PhoneNumber.find_by_number( @sms.to ).first
  end
  




#   def record_unsolicited_message()
#     message_status = self.internal_phone_number.organization.twilio_account.sms.messages.get( self.provider_update[:sms_sid] )
#     ledger_entry = self.internal_phone_number.ledger_entries.create( narrative: LedgerEntry::UNSOLICITED_SMS_NARRATIVE, price: message_status.price, notes: self.provider_update.to_property_hash )
#   end

#   def send_reply_to_unsolicited_message()
#     message_status = self.internal_phone_number.organization.send_sms( self.provider_update[:from], self.provider_update[:to], self.internal_phone_number.unsolicited_sms_message )
#     ledger_entry = self.internal_phone_number.ledger_entries.create( narrative: LedgerEntry::UNSOLICITED_SMS_REPLY_NARRATIVE, price: message_status.price, notes: self.provider_update )
#   end






  
  
  ##
  # Update the conversation...
#   def update_conversation( conversation )
#     conversation.response_received_at = DateTime.now
#     
#     # Update the conversation based upon the given value
#     conversation.status = case Conversation.normalize_message(self.provider_update[:body])
#       when conversation.normalized_expected_confirmed_answer
#         Conversation::CONFIRMED
#       when conversation.normalized_expected_denied_answer
#         Conversation::DENIED
#       else
#         Conversation::FAILED
#     end
#   end
  
#   def add_message_to_conversation( conversation )
#     message = conversation.messages.build( twilio_sid: self.provider_update[:sms_sid], message_kind: Message::REPLY, payload: self.provider_update )
#     pp message.twilio_status.to_property_hash
#     message.callback_payload = message.twilio_status.to_property_hash unless message.has_provider_price?
#     message.save!
#   end

  ##
  # Standardise the callback values by converting to a string, stripping, and underscoring.
  def normalize_provider_update( values=nil )
    values = self.provider_update.dup if values.nil?
    standardised = HashWithIndifferentAccess.new
    values.each { |key,value| standardised[key.to_s.strip.underscore] = value }
    return standardised
  end
  
  def normalize_provider_update!()
    self.provider_update = self.normalize_provider_update( self.provider_update )
  end

  alias :run :perform

end
