class MembershipDecorator < ApplicationDecorator
  delegate_all
  
  decorates_association :user
  decorates_association :team
  
  def owner_checkmark?
    checkmark model.team.owner == h.current_user
  end
  
  def administrator_checkmark?
    checkmark model.administrator?
  end

  def billing_liaison_checkmark?
    checkmark model.billing_liaison?
  end

  def developer_checkmark?
    checkmark model.developer?
  end

  def conversation_manager_checkmark?
    checkmark model.conversation_manager?
  end

end
