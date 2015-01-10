class UserDecorator < ApplicationDecorator
  delegate_all
  
  decorates_association :memberships, with: MembershipDecorator
  decorates_association :owned_teams, with: TeamDecorator
  
  def email_link
    h.mail_to email
  end

end
