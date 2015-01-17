class TeamDecorator < ApplicationDecorator
  delegate_all
  
  decorates_association :owner,       with: UserDecorator
  decorates_association :users,       with: UserDecorator
  decorates_association :memberships, with: MembershipDecorator

  def link_to_owner
    h.link_to_if h.policy(model.owner).show?, model.owner.name, model.owner
  end
  
end
