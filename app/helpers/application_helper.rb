module ApplicationHelper

  def navigation_list( entries = [], options = {} )
    render partial: 'layouts/navlist', object: entries, locals: { options: options }
  end
  
  def dropdown_list( label, entries = [], options = {} )
    entries.select! { |entry| entry.fetch(:if, true) }
    render partial: 'layouts/dropdown', object: entries, locals: { label: label, options: options }
  end
  
  def split_dropdown_list( entries = [], options = {} )
    entries.select! { |entry| entry.fetch(:if, true) }
    render partial: 'layouts/splitdropdown', object: entries, locals: { options: options } unless entries.empty?
  end
  
  def icon( kind = :blank, options = {} )
    #render partial: 'layouts/icon', object: ICONS.fetch( kind, kind ).to_s, locals: { options: options }
    kind = ICONS.fetch( kind, kind ).to_s

    i_class = options.fetch(:class, '')
    i_class = i_class.concat(' ') if i_class.is_a?(Array)

    i_style = options.fetch(:style, '')
    i_style = i_style.concat(' ') if i_style.is_a?(Array)

    return "<i class='icon-#{kind.to_s} #{i_class}' style='#{i_style}'></i>".html_safe
  end

  def header_icon( kind = :blank, options = {} )
    options = { class: 'header-icon' }.merge options
    icon( kind, options )
  end
  
  def humanize_phone_number( number )
    PhoneTools.humanize( number )
  end
  
  def flag_icon( country='_global', size='medium' )
    country_name = Country[country].name rescue nil
    image_tag 'flags/%s/%s.png' % [size.downcase, country.downcase], alt: country_name, title: country_name, style: 'vertical-align: bottom'
  end

end
