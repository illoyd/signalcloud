class MicrosoftExcelBox < Box

  has_attached_file :document

  validates_attachment :document,
    presence: true,
    content_type: { content_type: [ 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ] },
    if: :draft?

protected
    
  def start
    # Delete the attachment
    self.document = nil
    
    # Perform super function
    super
  end

end