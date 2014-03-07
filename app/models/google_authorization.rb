class GoogleAuthorization < Authorization

  def fetch_details
    # Todo
  end
  
  def refresh
    
    self
  end
  
  def google_drive
    @google_drive ||= GoogleDrive.login_with_oauth( self.token )
  end
  
  def spreadsheets
    self.google_drive.spreadsheets
  end
  
  def spreadsheet_options
    self.spreadsheets.map do |spreadsheet|
      [ spreadsheet.title, spreadsheet.human_url ]
    end
  end
  
  def spreadsheet( url )
    self.google_drive.spreadsheet_by_url( url )
  end
  
end
