class ThenClausePolicy < ApplicationPolicy

  def create?
    update?
  end

  def update?
    user.membership_for(record.if_clause.parent.team).developer?
  end
  
  def destroy?
    update?
  end
  
  def cache_key
    [ record, { create: create?, update: update?, destroy: destroy? } ]
  end
  
  class Scope < Scope
    def resolve
      scope.joins(if_clause: :parent).where('stencil.team_id in (?)', user.team_ids)
    end
  end

end
