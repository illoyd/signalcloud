module LedgerEntriesHelper

  def item_link( item )
    return case item.class.to_s
      when 'Message'
        item.ticket
      when 'PhoneNumber', 'UnsolicitedMessage', 'UnsolicitedCall'
        item
      else
        item.class.to_s
    end
  end

  def item_label( item )
    return case item.class.to_s
      when 'Message'
        'Ticket'
      when 'PhoneNumber'
        'Phone Number'
      when 'UnsolicitedMessage'
        'Message'
      when 'UnsolicitedCall'
        'Call'
      else
        'Unknown item...'
    end
  end

  def item_icon( item )
    return case item.class.to_s
      when 'Message'
        :tickets
      when 'PhoneNumber'
        :phone_numbers
      when 'UnsolicitedMessage'
        :phone_numbers
      when 'UnsolicitedCall'
        :phone_numbers
      else
        nil
    end
  end

end
