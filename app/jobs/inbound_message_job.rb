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
# This class is intended for use with Sidekiq.
#
class InboundMessageJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default
  
  attr_accessor :sms, :internal_phone_number, :provider_update
  
  def provider_update=(value)
    @provider_update = value
    @sms ||= Twilio::InboundSms.new( @provider_update )
  end

  def perform( provider_update )
    # Save for future use
    @provider_update = provider_update
    @sms ||= Twilio::InboundSms.new( provider_update )
    
    # Find all open conversations
    open_conversations = self.find_open_conversations()
    
    case open_conversations.count
      # No open conversations found; treat as an unsolicited message.
      when 0
        logger.info{ 'Received an unsolicited message.' }
        self.perform_unsolicited_action()
      
      # Only one conversation, so process immediately
      when 1
        logger.info{ 'Received a reply to conversation %i.' % [open_conversations.first.id] }
        self.perform_matching_conversation_action( open_conversations.first )

      # More than 1, so scan for possible positive or negative match.
      else
        logger.info{ 'Received a reply to multiple conversations %s' % [open_conversations.pluck(:id).to_s] }
        self.perform_multiple_matching_conversations_action( open_conversations )
    end
  end
  
  def perform_unsolicited_action()
    unsolicited_message = self.internal_phone_number.unsolicited_messages.build( provider_sid: @sms.sid, customer_number: @sms.from, received_at: DateTime.now, message_content: @provider_update )
    
    if self.internal_phone_number().should_reply_to_unsolicited_sms?
      unsolicited_message.action_taken = PhoneNumber::REPLY
      unsolicited_message.deliver_reply!
      SendUnsolicitedMessageReplyJob.perform_async( self.internal_phone_number.id, @provider_update[:from] )
    else
      unsolicited_message.action_taken = PhoneNumber::IGNORE
    end

    unsolicited_message.save!
  end
  
  def perform_matching_conversation_action( conversation )
    conversation.with_lock do
      # Move conversation to receiving state
      conversation.receive!
      
      # Create the internal message
      message = conversation.messages.create!( provider_sid: @sms.sid, from_number: @sms.from, to_number: @sms.to, body: @sms.body, message_kind: Message::RESPONSE, direction: Message::IN, provider_response: @provider_update )
      message.receive!
      
      # Move conversation to received state
      conversation.received!
  
      # Accept the answer
      conversation.accept_answer! @sms.body
      
      # Save the damn fool
      conversation.save!
    end
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
  # Intuit the appropriate conversation based upon the TO and FROM.
  # In this situation, we SWAP the given TO and FROM, as this is a reply from the user. Conversations are always from: SignalCloud, to: the recepient.
  def find_open_conversations()
    Conversation.find_open_conversations( @sms.to, @sms.from ).order( 'challenge_sent_at' )
  end
  
  def internal_phone_number()
    @internal_phone_number ||= PhoneNumber.find_by_number( @sms.to ).first
  end

  alias :run :perform

end
