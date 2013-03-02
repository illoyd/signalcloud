##
# Settle all outstanding (e.g. pending) messages.
# This tool will find all messages which do not have a 'sent' or 'received' status and attempt to settle them with
# Twilio. This will also attempt to force pricing information.
#
# This class is intended for use with Delayed::Job.
#
class SettleOutstandingMessagesJob < Struct.new( :account_id, :ignore_account_ids )
  include Talkable
  
  TEST_CREDENTIAL_ERROR = 20008

  def perform
    self.ignore_account_ids ||= []
    @last_account_id = nil

    self.outstanding_messages.find_each( batch_size: 100 ) do |message|
      begin
        @last_account_id = message.account.id
        if self.ignore_account_ids.include? message.account.id
          puts 'Skipping message %i as its account is on the ignore list.' % message.id
        else
          puts 'Attempting to settle message %i...' % message.id
          message.refresh_from_twilio!
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
  
  def outstanding_messages
    query = self.account_id.blank? ? Message : Account.find(self.account_id).messages
    query.outstanding
  end
  
  alias :run :perform

end
