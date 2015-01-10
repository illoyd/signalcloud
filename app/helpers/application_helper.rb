module ApplicationHelper

  ##
  # Create a font-awesome icon
  def icon( kind = :blank, options = {} )
    kind = ICONS.fetch(kind, kind.to_s.gsub(/_/, '-'))
    options[:class] = [ 'fa', "fa-#{kind}", options[:class] ].compact
    content_tag(:i, '', options)
  end
  
  ##
  # Prefix a string with an icon
  def iconify(label, icon, options = {})
    "#{ icon(icon, options) } #{ label }".strip.html_safe
  end

end
