module TicketsHelper
 
  def stencil_dropdown_list( current_account, current_stencil )
    # Pick the dropdown list title
    title = 'Stencil: ' + ( current_stencil.nil? ? 'All' : current_stencil.label )
    
    # Assemble the entries based upon the current
    entries = [] # [ { label: 'Show all tickets', icon: 'ok-circle', link: tickets_path } ]
    current_account.stencils.order(:label).each do |stencil|
      entries << { label: 'Show ' + stencil.label, icon: :stencils, link: stencil_tickets_path( stencil ) }
    end
    
    dropdown_list( title, entries, {class: 'btn-mini'} )
  end
  
  def status_dropdown_list( current_account, current_stencil, current_status )
    # Pick the dropdown list title
    title = 'Status: ' + ( current_status.nil? ? 'All' : human_ticket_status(current_status) )
    
    # Assemble the entries based upon the current
    entries = [
      { label: 'Show all statuses', icon: 'ok-circle', link: current_stencil.nil? ? tickets_path : stencil_tickets_path( current_stencil ) },
      { label: 'Show Opened', icon: 'plus-sign', link: current_stencil.nil? ? open_tickets_path : open_stencil_tickets_path( current_stencil ) },
      { label: 'Show Confirmed', icon: 'ok-sign', link: current_stencil.nil? ? confirmed_tickets_path : confirmed_stencil_tickets_path( current_stencil ) },
      { label: 'Show Denied', icon: 'minus-sign', link: current_stencil.nil? ? denied_tickets_path : denied_stencil_tickets_path( current_stencil ) },
      { label: 'Show Failed', icon: 'remove-sign', link: current_stencil.nil? ? failed_tickets_path : failed_stencil_tickets_path( current_stencil ) },
      { label: 'Show Expired', icon: :time, link: current_stencil.nil? ? expired_tickets_path : expired_stencil_tickets_path( current_stencil ) }
    ]

    dropdown_list( title, entries, {class: 'btn-mini'} )
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
  
  def ticket_status_icon( status )
    ii = case status
      when Ticket::PENDING, Ticket::QUEUED, Ticket::CHALLENGE_SENT, Ticket::OPEN_STATUSES
        'plus-sign'
      when Ticket::CONFIRMED
        'ok-sign'
      when Ticket::DENIED
        'minus-sign'
      when Ticket::FAILED
        'remove-sign'
      when Ticket::EXPIRED
        'time'
      else
        'Other: ' + status.to_s
    end
    return icon( ii )
  end

  def human_ticket_status( status )
    return case status
      when Ticket::PENDING, Ticket::QUEUED
        'Queued'
      when Ticket::CHALLENGE_SENT, Ticket::OPEN_STATUSES
        'Open'
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
