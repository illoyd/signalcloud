module ApplicationHelper

  def navigation_list( entries = [], options = {} )
    render partial: 'layouts/navlist', object: entries, locals: { options: options }
  end
  
  def dropdown_list( label, entries = [], options = {} )
    render partial: 'layouts/dropdown', object: entries, locals: { label: label, options: options }
  end
  
  def icon( kind = :blank, options = {} )
    render partial: 'layouts/icon', object: ICONS.fetch( kind, kind ).to_s, locals: { options: options }
  end

  def header_icon( kind = :blank, options = {} )
    options = { class: 'header-icon' }.merge options
    icon( kind, options )
  end
  
  def humanize_phone_number( number )
    PhoneTools.humanize( number )
  end
  
  def flag_icon( country='global', size='medium' )
    image_tag 'flag-%s-%s.png' % [country.downcase, size.downcase], { style: 'vertical-align: bottom' }
  end

end
