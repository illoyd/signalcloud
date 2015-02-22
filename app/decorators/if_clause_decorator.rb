class IfClauseDecorator < ApplicationDecorator
  delegate_all
  decorates_association :then_clauses, with: ThenClauseDecorator

  def name
    model.class.name[/If(.+)Clause/, 1].underscore.titleize
  end
  
  def new_with_modal(label = nil)
    label ||= h.icon(:new)
    if h.policy(model).new?
      h.link_to label, '#', class: 'btn btn-xs btn-default', data: { toggle: 'modal', target: "#edit_#{ model.class.name.underscore }_#{ model.id || 'new' }", 'parent-id' => model.parent_id }
    end
  end
  
  def edit_with_modal(label = nil)
    label ||= h.icon(:edit)
    if h.policy(model).edit?
      h.link_to label, '#', class: 'btn btn-xs btn-default', data: { toggle: 'modal', target: "#edit_#{ model.class.name.underscore }_#{ model.id || 'new' }" }
    end
  end

  def destroy_with_modal(label = nil)
    label ||= h.icon(:delete)
    if h.policy(model).destroy?
      h.link_to label, '#', class: 'btn btn-xs btn-default', data: { toggle: 'modal', target: "#destroy_#{ model.class.name.underscore }_#{ model.id || 'new' }" }
    end
  end

  def edit_modal
    if h.policy(model).edit? && !@edit_modal_printed
      @edit_modal_printed = true
      h.render partial: "#{ model.class.name.pluralize.underscore }/edit_modal", object: self, as: model.class.name.underscore.to_sym
    end
  end

  def destroy_modal
    if h.policy(model).destroy? && !@destroy_modal_printed
      @destroy_modal_printed = true
      h.render partial: "#{ model.class.name.pluralize.underscore }/destroy_modal", object: self, as: model.class.name.underscore.to_sym
    end
  end

end
