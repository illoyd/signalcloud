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
    Phony.formatted( Phony.normalize( number ) )
  end

end
