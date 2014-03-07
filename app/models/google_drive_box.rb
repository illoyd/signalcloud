class GoogleDriveBox < Box

  validates_presence_of :document
  
protected
  
  def read_conversations
    token = ( current_user || self.user ).authorization_for(:google).token
    self.reader.parse( self.document_file_name, access_token: token  )
  end
  
  def export
    super
    
    # Export results data
    
  end

end