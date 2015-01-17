class ApplicationDecorator < Draper::Decorator

  def description
    if model.description.blank?
      h.content_tag(:span, 'No description provided', class: 'text-muted')
    else
      h.simple_format(model.description)
    end
  end

  def link_to
    h.link_to_if h.policy(object).show?, self.try(:display_name) || self.try(:name) || object.class.name, object
  end
  
  def show_button
    h.link_to(h.icon(:show), object, class: 'btn btn-xs btn-default') if h.policy(object).show?
  end
  
  def edit_button
    h.link_to(h.icon(:edit), [:edit, object], class: 'btn btn-xs btn-default') if h.policy(object).edit?
  end
  
  def active_checkmark
    checkmark(active?)
  end
  
  def checkmark(flag)
    h.icon(flag ? :active : :inactive)
  end

  def status
    ws = workflow_state || :active
    h.iconify(ws.to_s.humanize, ws)
  end
  
  alias_method :workflow_state_with_icon, :status
end
