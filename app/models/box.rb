class Box < ActiveRecord::Base
  include Workflow
  workflow do
    state :draft do
      event :start, transitions_to: :working
      event :refresh, transitions_to: :draft
    end
    state :working do
      event :complete, transitions_to: :complete
    end
    state :complete
  end
  
  belongs_to :organization, inverse_of: :boxes
  has_many :conversations, inverse_of: :box, dependent: :destroy
  
  has_attached_file :document

  validates :organization, presence: true
  validates :document, attachment_presence: true, attachment_content_type: [ 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ], if: :draft?
  
  protected
  
  def refresh
    # Delete all existing draft conversations
    self.conversations.with_draft_state.clear
    
    # Reload from document
    self.conversations = ConversationWorkbookReader.parse( self.document )
  end
  
  def start
    # Delete the attachment
    self.document = nil
  
    # Initiate new start jobs for all conversations
    self.conversations.pluck(:id).each do |conversation_id|
      SendConversationChallengeJob.perform_async( conversation_id )
    end
  end
  
  def complete
    # Send a notice that the box is done
  end
  
end
