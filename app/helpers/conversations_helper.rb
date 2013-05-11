module ConversationsHelper
 
  def stencil_dropdown_list( current_organization, current_stencil )
    # Pick the dropdown list title
    title = 'Stencil: ' + ( current_stencil.nil? ? 'All' : current_stencil.label )
    
    # Assemble the entries based upon the current
    entries = [] # [ { label: 'Show all conversations', icon: 'ok-circle', link: conversations_path } ]
    current_organization.stencils.order(:label).each do |stencil|
      entries << { label: 'Show ' + stencil.label, icon: :stencils, link: stencil_conversations_path( stencil ) }
    end
    
    dropdown_list( title, entries, {class: 'btn-mini'} )
  end
  
  def status_dropdown_list( current_organization, current_stencil, current_status )
    # Pick the dropdown list title
    title = 'Status: ' + ( current_status.nil? ? 'All' : human_conversation_status(current_status) )
    
    # Assemble the entries based upon the current
    entries = [
      { label: 'Show all statuses', icon: 'ok-circle', link: current_stencil.nil? ? conversations_path : stencil_conversations_path( current_stencil ) },
      { label: 'Show Opened', icon: 'plus-sign', link: current_stencil.nil? ? open_conversations_path : open_stencil_conversations_path( current_stencil ) },
      { label: 'Show Confirmed', icon: 'ok-sign', link: current_stencil.nil? ? confirmed_conversations_path : confirmed_stencil_conversations_path( current_stencil ) },
      { label: 'Show Denied', icon: 'minus-sign', link: current_stencil.nil? ? denied_conversations_path : denied_stencil_conversations_path( current_stencil ) },
      { label: 'Show Failed', icon: 'remove-sign', link: current_stencil.nil? ? failed_conversations_path : failed_stencil_conversations_path( current_stencil ) },
      { label: 'Show Expired', icon: :time, link: current_stencil.nil? ? expired_conversations_path : expired_stencil_conversations_path( current_stencil ) }
    ]

    dropdown_list( title, entries, {class: 'btn-mini'} )
  end
  
  def conversation_class( status )
    return case status
      #when Conversation::QUEUED
      #  ''
      when Conversation::CHALLENGE_SENT
        'info'
      when Conversation::CONFIRMED
        'success'
      when Conversation::DENIED
        'error'
      when Conversation::FAILED
        'error'
      when Conversation::EXPIRED
        'warning'
      else
        ''
    end
  end
  
  def conversation_status_icon( status )
    ii = case status
      when Conversation::PENDING, Conversation::QUEUED, Conversation::CHALLENGE_SENT, Conversation::OPEN_STATUSES
        'plus-sign'
      when Conversation::CONFIRMED
        'ok-sign'
      when Conversation::DENIED
        'minus-sign'
      when Conversation::FAILED
        'remove-sign'
      when Conversation::EXPIRED
        'time'
      else
        'Other: ' + status.to_s
    end
    return icon( ii )
  end

  def human_conversation_status( status )
    return case status
      when Conversation::PENDING, Conversation::QUEUED
        'Queued'
      when Conversation::CHALLENGE_SENT, Conversation::OPEN_STATUSES
        'Open'
      when Conversation::CONFIRMED
        'Confirmed'
      when Conversation::DENIED
        'Denied'
      when Conversation::FAILED
        'Failed'
      when Conversation::EXPIRED
        'Expired'
      else
        'Other: ' + status.to_s
    end
  end

end
