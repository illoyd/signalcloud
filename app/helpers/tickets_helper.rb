module TicketsHelper
 
  def appliance_dropdown_list( current_account, current_appliance )
    # Pick the dropdown list title
    title = 'Appliance: ' + ( current_appliance.nil? ? 'All' : current_appliance.label )
    
    # Assemble the entries based upon the current
    entries = [ { label: 'Show all tickets', icon: 'ok-circle', link: tickets_path } ]
    current_account.appliances( order: :label ).each do |appliance|
      entries << { label: 'Filter by ' + appliance.label, icon: :appliances, link: appliance_tickets_path( appliance ) }
    end
    
    dropdown_list( title, entries )
  end
  
  def status_dropdown_list( current_account, current_appliance, current_status )
    # Pick the dropdown list title
    title = 'Status: ' + ( current_status.nil? ? 'All' : human_ticket_status(current_status) )
    
    # Assemble the entries based upon the current
    entries = [
      { label: 'Show all statuses', icon: 'ok-circle', link: current_appliance.nil? ? tickets_path : appliance_tickets_path( current_appliance ) },
      { label: 'Filter by Opened', icon: 'plus-sign', link: current_appliance.nil? ? open_tickets_path : open_appliance_tickets_path( current_appliance ) },
      { label: 'Filter by Confirmed', icon: 'ok-sign', link: current_appliance.nil? ? confirmed_tickets_path : confirmed_appliance_tickets_path( current_appliance ) },
      { label: 'Filter by Denied', icon: 'minus-sign', link: current_appliance.nil? ? denied_tickets_path : denied_appliance_tickets_path( current_appliance ) },
      { label: 'Filter by Failed', icon: 'remove-sign', link: current_appliance.nil? ? failed_tickets_path : failed_appliance_tickets_path( current_appliance ) },
      { label: 'Filter by Expired', icon: :time, link: current_appliance.nil? ? expired_tickets_path : expired_appliance_tickets_path( current_appliance ) }
    ]

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
