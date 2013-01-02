module ApplicationHelper

  def navigation_list( entries = [], options = {} )
    render partial: 'layouts/navlist', object: entries, locals: { options: options }
  end
  
  def dropdown_list( label, entries = [], options = {} )
    render partial: 'layouts/dropdown', object: entries, locals: { label: label, options: options }
  end
  
  def icon( kind = :blank )
    render partial: 'layouts/icon', object: ICONS.fetch( kind, kind ).to_s
  end

end
