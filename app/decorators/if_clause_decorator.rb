class IfClauseDecorator < ApplicationDecorator
  delegate_all
  decorates_association :then_clauses, with: ThenClauseDecorator
end
