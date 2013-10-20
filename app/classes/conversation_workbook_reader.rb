class ConversationWorkbookReader

  attr_accessor :document, :stencil, :headers, :keys

  def self.parse( stencil, document )
    reader = ConversationWorkbookReader.new( document )
    reader.read( document )
  end
  
  def initialize( stencil, document )
    self.stencil = stencil
    self.document = document
  end
  
  def read
    conversations = []

    self.book.worksheets.each do |worksheet|
      conversations += read_worksheet(worksheet)
    end

    conversations
  end
  
  def book
    @book ||= Spreadsheet.open self.document
  end
  
  protected
  
  def build_conversation( params )
    self.stencil.open_conversation( safe_params( params ) )
  end
  
  def safe_params( params )
    params = ActionController::Parameters.new(params)
    params.require( :conversation ).permit( :seconds_to_live, :stencil_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :internal_number, :question, :customer_number, :expires_at, :webhook_uri, :parameters, :parameters_as_assignments )
  end
  
  def read_worksheet( worksheet )
    # Read in the header
    @index = 0
    read_header( worksheet )
    
    # Read in all data
    worksheet.rows.each(@index) { |row| read_row(row) }
  end
  
  def read_header( worksheet )
    worksheet.each do |row|
      @index += 1
      @headers = []
      @keys = HashWithIndifferentAccess.new
      row.each_with_index do |key, index|
        key = key.to_s.underscore
        @headers << key
        @keys[key] = index
      end
      break
    end
  end
  
  def read_row( row )
    values = HashWithIndifferentAccess.new
    row.each_with_index do |value, index|
      values[header(index)] = value
    end
    values
  end
  
  def cell( row, column )
    row[column(column)]
  end
  
  def header(column)
    @headers[column]
  end
  
  def column(header)
    @keys[header]
  end

end