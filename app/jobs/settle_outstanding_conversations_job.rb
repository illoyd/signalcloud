##
# Settle all outstanding (e.g. pending) conversations.
# This tool will find all conversations which do not have a 'sent' or 'received' status and attempt to settle based
# on message statuses.
#
# This class is intended for use with Sidekiq.
#
class SettleOutstandingConversationsJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background
  
  TEST_CREDENTIAL_ERROR = 20008

  def perform( organization_id=nil, ignore_organization_ids=[] )
    ignore_organization_ids ||= []
    @last_organization_id = nil

    self.outstanding_conversations.find_each( batch_size: 100 ) do |conversation|
      begin
        @last_organization_id = conversation.organization.id
        if ignore_organization_ids.include? @last_organization_id
          logger.debug{ 'Skipping conversation %i as its organization is on the ignore list.' % conversation.id }
        else
          logger.debug{ 'Attempting to settle conversation %i...' % conversation.id }
          conversation.settle_messages_statuses!
        end
  
      rescue Twilio::REST::RequestError => ex
        case ex.code 
          when TEST_CREDENTIAL_ERROR
            logger.warn{ 'Organization %i is not accessible (code: %s).' % [ @last_organization_id, ex.code ] }
            ignore_organization_ids << @last_organization_id
          else
            raise ex
        end
      end

    end
  end
  
  def outstanding_conversations(organization_id=nil)
    query = organization_id.blank? ? Conversation : Organization.find(organization_id).conversations
    query.outstanding
  end
  
  alias :run :perform

end
