class UserPolicy < ApplicationPolicy
  
  def show?
    scope.where(id: record.id).exists?
  end

  def update?
    user == record
  end
  
  class Scope < Scope
    def resolve
      scope.where(id: user.memberships.pluck(:team_id))
    end
  end

end
