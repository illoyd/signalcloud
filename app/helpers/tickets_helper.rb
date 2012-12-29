module TicketsHelper
 
  def appliance_dropdown_list( current_account, current_appliance )
    # Pick the dropdown list title
    title = 'Current Filter: ' + ( current_appliance.nil? ? 'All' : current_appliance.label )
    
    # Assemble the entries based upon the current
    entries = [ { label: 'Show all tickets', icon: 'ok-circle', link: tickets_path } ]
    current_account.appliances( order: :label ).each do |appliance|
      entries << { label: 'Filter by ' + appliance.label, icon: :appliances, link: appliance_tickets_path( appliance ) }
    end
    
    dropdown_list( title, entries )
  end
  
  def ticket_class( status )
    return case status
      #when Ticket::QUEUED
      #  ''
      when Ticket::CHALLENGE_SENT
        'info'
      when Ticket::CONFIRMED
        'success'
      when Ticket::DENIED
        'error'
      when Ticket::FAILED
        'error'
      when Ticket::EXPIRED
        'warning'
      else
        ''
    end
  end
  
  def human_ticket_status( status )
    return case status
      when Ticket::QUEUED
        'Queued'
      when Ticket::CHALLENGE_SENT
        'Sent'
      when Ticket::CONFIRMED
        'Confirmed'
      when Ticket::DENIED
        'Denied'
      when Ticket::FAILED
        'Failed'
      when Ticket::EXPIRED
        'Expired'
      else
        'Other: ' + status.to_s
    end
  end

end
