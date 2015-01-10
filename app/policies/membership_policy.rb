class MembershipPolicy < ApplicationPolicy
  
  def show?
    update? || scope.where(id: record.id).exists?
  end
  
  def create?
    update?
  end
  
  def update?
    record.team.owner == user || user.membership_for(record.team).admin?
  end
  
  def destroy?
    update?
  end
  
  class Scope < Scope
    def resolve
      team_ids = user.memberships.select(:team_id).distinct
      scope.where('memberships.id in (?)', team_ids)
    end
  end

end
