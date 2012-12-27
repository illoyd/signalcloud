module Ticketplease

class TicketpleaseError < StandardError
  attr_accessor :code
  
  def initialize( msg = nil, code = nil )
    super( msg )
    self.code = code
  end

end

class AccountNotAssociatedError < TicketpleaseError
  def initialize()
    super( 'Account not associated to object' )
  end
end


end