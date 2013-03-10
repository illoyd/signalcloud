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
    self.account.create_twilio_account
    self.account.create_twilio_application
    self.account.save!
  end
  
  def account
    @account ||= Account.find( account_id )
  end
  
  alias :run :perform

end
