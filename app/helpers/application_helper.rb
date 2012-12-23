module ApplicationHelper

  def navigation_list( entries = [] )
    render partial: 'layouts/navlist', object: entries
  end
  
  def icon( kind = :blank )
    render partial: 'layouts/icon', object: ICONS.fetch( kind, kind ).to_s
  end

end
