##
# Read a spreadsheet from Google Drive
# Requires the following items
#   +conversation_id+: the unique identifier for the conversation
#   +force_resend+: a flag to indicate if this is a forced resend; defaults to +false+
#
# This class is intended for use with Sidekiq.
#
class RefreshBoxConversationsJob
  include Sidekiq::Worker
  sidekiq_options :queue => :background
  
  def perform( box_id )
    box = Box.where( id: box_id ).with_draft_state
    box.refresh!
  end

end