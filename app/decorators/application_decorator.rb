class ApplicationDecorator < Draper::Decorator

  def link_to
    h.link_to_if h.policy(model).show?, name, model
  end
  
  def show_button
    h.link_to(h.icon(:show), model, class: 'btn btn-xs btn-default') if h.policy(model).show?
  end
  
  def edit_button
    h.link_to(h.icon(:edit), [:edit, model], class: 'btn btn-xs btn-default') if h.policy(model).edit?
  end
  
  def active_checkmark
    checkmark(active?)
  end
  
  def checkmark(flag)
    h.icon(flag ? :active : :inactive)
  end

  def workflow_state_with_icon
    ws = workflow_state || :active
    h.iconify(ws.to_s.humanize, ws)
  end
end
