class PhoneBookEntryPolicy < ApplicationPolicy

  def create?
    update?
  end

  def update?
    user.membership_for(record.team).developer?
  end
  
  def destroy?
    update?
  end
  
  def cache_key
    [ record, { create: create?, update: update?, destroy: destroy? } ]
  end
  
  class Scope < Scope
    def resolve
      scope.where(team_id: user.team_ids)
    end
  end

end
