class TeamPolicy < ApplicationPolicy
  
  def show?
    update? || scope.where(id: record.id).exists?
  end
  
  def create?
    true
  end
  
  def update?
    record.owner == user
  end

  class Scope < Scope
    def resolve
      team_ids = user.memberships.select(:team_id).distinct
      scope.where(id: team_ids)
    end
  end
end
