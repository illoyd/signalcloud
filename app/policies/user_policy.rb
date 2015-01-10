class UserPolicy < ApplicationPolicy
  
  def show?
    update? || scope.where(id: record.id).exists?
  end

  def update?
    user == record
  end
  
  class Scope < Scope
    def resolve
      team_ids = user.memberships.select(:team_id).distinct
      user_ids = Membership.where(team_id: team_ids).select(:user_id).distinct
      scope.where('id in (?) OR id = ?', user_ids, user.id)
    end
  end

end
