module ApplicationHelper

  def navigation_list( entries = [] )
    render partial: 'layouts/navlist', object: entries
  end
  
  def dropdown_list( label, entries = [] )
    render partial: 'layouts/dropdown', object: entries, locals: { label: label }
  end
  
  def icon( kind = :blank )
    render partial: 'layouts/icon', object: ICONS.fetch( kind, kind ).to_s
  end

end
