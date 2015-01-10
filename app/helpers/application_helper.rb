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
  
  def navbar_link(path, label, icon = nil)
    # Hide the label
    label_span = content_tag(:span, label, class: 'sr-only')
    
    # Create a sane default icon
    icon ||= label.downcase.to_sym
    
    # Current label
    current_span = content_tag(:span, '(current)', class: 'sr-only') if current_page?(path)

    # Return a list item with the appropriate contents
    content_tag(:li, class: current_page?(path) ? 'active' : nil) do
      link_to(path) do
        iconify(label_span, icon) + current_span
      end
    end

  end

  def subnavbar_link(path, label, icon = nil)
    # Create a sane default icon
    icon ||= label.downcase.to_sym
    
    # Current label
    current_span = content_tag(:span, '(current)', class: 'sr-only') if current_page?(path)

    # Return a list item with the appropriate contents
    content_tag(:li, class: current_page?(path) ? 'active' : nil) do
      link_to(path) do
        iconify(label, icon) + current_span
      end
    end

  end

end
