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
    state :complete do
      event :export, transitions_to: :complete
    end
  end
  
  belongs_to :user, inverse_of: :boxes
  belongs_to :organization, inverse_of: :boxes
  has_many :conversations, inverse_of: :box, dependent: :destroy
  
  validates :organization, presence: true
  validates :user, presence: true
  
  def reader
    @reader ||= ConversationWorkbookReader.new
  end
  
  protected
  
  def read_conversations
    self.reader.parse( self.document_file_name )
  end
  
  def refresh
    # Delete all existing draft conversations
    self.conversations.with_draft_state.clear
    
    # Reload from document
    self.conversations = self.read_conversations
  end
  
  def start
    # Initiate new start jobs for all conversations
    self.conversations.pluck(:id).each do |conversation_id|
      SendConversationChallengeJob.perform_async( conversation_id )
    end
  end
  
  def complete
    # Send a notice that the box is done
  end
  
end
