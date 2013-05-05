##
# Settle all outstanding (e.g. pending) conversations.
# This tool will find all conversations which do not have a 'sent' or 'received' status and attempt to settle based
# on message statuses.
#
# This class is intended for use with Delayed::Job.
#
class SettleOutstandingConversationsJob < Struct.new( :account_id, :ignore_account_ids )
  include Talkable
  
  TEST_CREDENTIAL_ERROR = 20008

  def perform
    self.ignore_account_ids ||= []
    @last_account_id = nil

    self.outstanding_conversations.find_each( batch_size: 100 ) do |conversation|
      begin
        @last_account_id = conversation.account.id
        if self.ignore_account_ids.include? @last_account_id
          puts 'Skipping conversation %i as its account is on the ignore list.' % conversation.id
        else
          puts 'Attempting to settle conversation %i...' % conversation.id
          conversation.settle_messages_statuses!
        end
  
      rescue Twilio::REST::RequestError => ex
        case ex.code 
          when TEST_CREDENTIAL_ERROR
            puts 'Account %i is not accessible (code: %s).' % [ @last_account_id, ex.code ]
            ignore_account_ids << @last_account_id
          else
            raise ex
        end
      end

    end
  end
  
  def outstanding_conversations
    query = self.account_id.blank? ? Conversation : Account.find(self.account_id).conversations
    query.outstanding
  end
  
  alias :run :perform

end
