class ConversationWorkbookReader

  attr_accessor :document, :stencil, :options

  RESERVED_KEYS = [ :seconds_to_live, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :internal_number, :question, :customer_number, :webhook_uri, :parameters_as_assignments, :parameters ]

  ## Quickly build a reader and return its found conversations.
  def self.parse( stencil, document, options={} )
    reader = ConversationWorkbookReader.new( stencil )
    reader.read( document, options )
  end
  
  ##
  # Construct a brand-new reader, using a default stencil and pointing to a specific document.
  def initialize( stencil )
    self.stencil = stencil
  end
  
  ##
  # Process the given workbook.
  def read( document, options={} )
    self.document = document
    self.options = options

    conversations = []
    self.book.each_with_pagename do |name, worksheet|
      conversations = conversations + read_worksheet( worksheet )
    end
    conversations
  end

  ##
  # Return the current workbook, opening it if necessary.
  def book
    @book ||= Roo::Spreadsheet.open( self.document, self.options )
  end
  
  protected
  
  ##
  # Short-hand to safely build a conversation within the current stencil.
  def build_conversation( params )
    self.stencil.build_conversation( safe_params( params ) )
  end
  
  ##
  # Safely verify all parameters for insertion into a conversation model.
  def safe_params( params )
    params = ActionController::Parameters.new(params)
    params.require( :conversation ).permit( *RESERVED_KEYS ).tap do |whitelisted|
      whitelisted[:parameters] = params[:conversation][:parameters]
    end
  end
  
  ##
  # Process each row in the worksheet
  def read_worksheet( worksheet )
    conversations = []
    worksheet.each(headers: true) do |row|
      # Skip if this is the header row (weird bug in Roo?)
      next if row.fetch('internal_number', nil) == 'internal_number'

      # Otherwise process the row!
      row = clean_row(row).with_indifferent_access
      row[:parameters] = parameterise_row(row)
      conversation = build_conversation( { conversation: row } )
      conversation.render!
      conversations << conversation
    end
    conversations
  end
  
  ##
  # Remove all keys which are blank. This assumes that a blank value should be replaced by the default value from the stencil.
  def clean_row( row )
    row.reject { |key,value| value.blank? }
  end
  
  ##
  # Merge un-expected columns into a parameters field
  def parameterise_row( row )
    params = row.fetch(:parameters, HashWithIndifferentAccess.new)
    params.merge row.reject { |key,value| RESERVED_KEYS.include? key.to_sym }
  end

end