##
# Create a new Twilio Account for this account.
# Requires the following items
#   +account_id+: the account ID to process
#
# This class is intended for use with Delayed::Job.
#
class CreateTwilioAccountJob < Struct.new( :account_id )
  include Talkable

  def perform
    begin
      self.account.create_twilio_account!()
      self.account.save!
    rescue Ticketplease::TwilioAccountAlreadyExistsError => ex
      say( 'Twilio account already exists for account %s' % self.account.id, Logger::DEBUG )
      return true
    end
  end
  
  def account
    @account ||= Account.find( account_id )
  end
  
  alias :run :perform

end
