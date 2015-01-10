class MembershipDecorator < ApplicationDecorator
  delegate_all
  
  decorates_association :user
  decorates_association :team
  
  def owner_checkmark?
    checkmark model.team.owner == h.current_user
  end
  
  def admin_checkmark?
    checkmark model.admin?
  end

end
