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
  
  def edit_details?
    record.new_record? || user.membership_for(record).administrator?
  end

  def edit_billing_address?
    user.membership_for(record).billing_liaison?
  end

  class Scope < Scope
    def resolve
      team_ids = user.memberships.select(:team_id).distinct
      scope.where('teams.owner_id = ? OR teams.id in (?)', user.id, team_ids)
    end
  end
end
