class ConvesationWorkbookReader

  attr_accessor :document

  def self.parse( document )
    reader = ConversationWorkbookReader.new( document )
    reader.read( document )
  end
  
  def initialize( document )
    self.document = document
  end
  
  def read
    conversations = []

    @book.worksheets.each do |worksheet|
      conversations += read_worksheet(worksheet)
    end

    conversations
  end
  
  def book
    @book ||= Spreadsheet.open self.document
  end
  
  protected
  
  def build_conversation( params )
    params = safe_params( params )
  end
  
  def safe_params( params )
    params = ActionController::Parameters.new(params)
    params.require(:conversation).permit( :seconds_to_live, :stencil_id, :confirmed_reply, :denied_reply, :expected_confirmed_answer, :expected_denied_answer, :expired_reply, :failed_reply, :internal_number, :question, :customer_number, :expires_at, :webhook_uri )
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
      @header = []
      @keys = HashWithIndifferentAccess.new
      row.each_with_index do |key, index|
        key = key.to_s.underscore
        @header << key
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
    row[@keys[column]]
  end
  
  def header(index)
    @header[index]
  end

end