module ConversationsHelper
 
  def stencil_dropdown_list( current_organization, current_stencil )
    # Pick the dropdown list title
    title = 'Stencil: ' + ( current_stencil.nil? ? 'All' : current_stencil.label )
    
    # Assemble the entries based upon the current
    entries = [ { label: 'Show all conversations', icon: :conversations, link: organization_conversations_path(@organization) } ]
    current_organization.stencils.order(:label).each do |stencil|
      entries << { label: 'Show ' + stencil.label, icon: :stencils, link: organization_stencil_conversations_path( @organization, stencil ) }
    end
    
    dropdown_list( title, entries, {class: 'btn-xs'} )
  end
  
  def status_dropdown_list( current_organization, current_stencil, current_status )
    # Pick the dropdown list title
    title = 'Status: ' + ( current_status.nil? ? 'All' : human_conversation_status(current_status) )
    
    # Assemble the entries based upon the current
    entries = [
#       { label: 'Show all statuses', icon: 'ok-circle', link: current_stencil.nil? ? conversations_path : stencil_conversations_path( current_stencil ) },
#       { label: 'Show Opened', icon: 'plus-sign', link: current_stencil.nil? ? open_conversations_path : open_stencil_conversations_path( current_stencil ) },
#       { label: 'Show Confirmed', icon: 'ok-sign', link: current_stencil.nil? ? confirmed_conversations_path : confirmed_stencil_conversations_path( current_stencil ) },
#       { label: 'Show Denied', icon: 'minus-sign', link: current_stencil.nil? ? denied_conversations_path : denied_stencil_conversations_path( current_stencil ) },
#       { label: 'Show Failed', icon: 'remove-sign', link: current_stencil.nil? ? failed_conversations_path : failed_stencil_conversations_path( current_stencil ) },
#       { label: 'Show Expired', icon: :time, link: current_stencil.nil? ? expired_conversations_path : expired_stencil_conversations_path( current_stencil ) }
    ]

    dropdown_list( title, entries, {class: 'btn-xs'} )
  end
  
  def css_class_for( status )
    status = status.status if status.is_a? Conversation
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
  
  def status_icon_for( status )
    status = status.status if status.is_a? Conversation
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

  def human_status_for( status )
    status = status.status if status.is_a? Conversation
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
  
  alias_method :human_conversation_status, :human_status_for
  alias_method :conversation_status_icon, :status_icon_for
  alias_method :conversation_class, :css_class_for

end
