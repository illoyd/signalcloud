class ApplicationDecorator < Draper::Decorator

  def description
    if model.description.blank?
      h.content_tag(:span, 'No description provided', class: 'text-muted')
    else
      h.simple_format(model.description)
    end
  end

  def name_with_link(options = {})
    show_link(try(:display_name) || try(:name) || object.class.name.humanize, options)
  end
  
  def link_to
    h.link_to_if h.policy(object).show?, self.try(:display_name) || self.try(:name) || object.class.name, object
  end
  
  def show_button
#     h.link_to(h.icon(:show), object, class: 'btn btn-xs btn-default') if h.policy(object).show?
    show_link(h.icon(:show), class: 'btn btn-xs btn-default') if h.policy(object).show?
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
  
  ##
  # Show link
  def show_link(label, options)
    h.link_to_if(h.policy(object).show?, label, object, options)
  end
  
  ##
  # Edit link
  def edit_link(label, options)
    h.link_to_if(h.policy(object).edit?, label, [:edit, object], options)
  end
  
  ##
  # Activate link
  def activate_link(label, options)
    h.link_to_if(h.policy(object).activate?, label, [:activate, object], options)
  end
  
  ##
  # Deactivate link
  def deactivate_link(label, options)
    h.link_to_if(h.policy(object).deactivate?, label, [:deactivate, object], options)
  end
  
  ##
  def small_show_button
    show_link(
      h.icon(:show),
      class: 'btn btn-xs btn-default'
    ) if object.persisted? && h.policy(object).show?
  end
  
  ##
  def small_edit_button
    edit_link(
      h.icon(:edit),
      class: 'btn btn-xs btn-default'
    ) if object.persisted? && h.policy(object).edit?
  end
  
  ##
  # Toolbar show button
  def toolbar_show_button
    show_link(
      h.iconify('Details', :show),
      class: 'btn btn-default'
    ) if object.persisted? && h.policy(object).show?
  end
  
  ##
  # Toolbar edit button
  def toolbar_edit_button
    edit_link(
      h.iconify('Edit', :edit),
      class: 'btn btn-default'
    ) if object.persisted? && h.policy(object).edit?
  end
end
