##
# Settle all outstanding (e.g. pending) messages.
# This tool will find all messages which do not have a 'sent' or 'received' status and attempt to settle them with
# Twilio. This will also attempt to force pricing information.
#
# This class is intended for use with Sidekiq.
#
class SettleOutstandingMessagesJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background
  
  TEST_CREDENTIAL_ERROR = 20008

  def perform( organization_id=nil, ignore_organization_ids=[] )
    ignore_organization_ids ||= []
    @last_organization_id = nil

    outstanding_messages.find_each( batch_size: 100 ) do |message|
      begin
        @last_organization_id = message.organization.id
        if ignore_organization_ids.include? message.organization.id
          logger.debug{ 'Skipping message %i as its organization is on the ignore list.' % message.id }
        else
          logger.debug{ 'Attempting to settle message %i (%s)...' % [ message.id, message.twilio_sid ] }
          message.refresh_from_twilio!
        end
  
      rescue Twilio::REST::RequestError => ex
        case ex.code 
          when TEST_CREDENTIAL_ERROR
            puts 'Organization %i is not accessible (code: %s).' % [ @last_organization_id, ex.code ]
            ignore_organization_ids << @last_organization_id
          else
            raise ex
        end
      end

    end
  end
  
  def outstanding_messages(organization_id=nil)
    query = organization_id.blank? ? Message : Organization.find(organization_id).messages
    query.where( 'twilio_sid is not null' ).outstanding
  end
  
  alias :run :perform

end
