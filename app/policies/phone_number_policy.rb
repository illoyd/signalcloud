class PhoneNumberPolicy < ApplicationPolicy

  def update?
    user.membership_for(record.team).developer?
  end
  
  def purchase?
    update? && record.can_purchase?
  end
  
  def release?
    update? && record.can_release?
  end
  
  def cache_key
    [ record, { update: update?, purchase: purchase?, release: release? } ]
  end
  
  class Scope < Scope
    def resolve
      scope.where(team_id: user.team_ids)
    end
  end

end
