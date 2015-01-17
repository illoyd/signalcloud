class StencilDecorator < ApplicationDecorator
  delegate_all

  decorates_association :phone_book, with: PhoneBookDecorator
  decorates_association :if_clauses, with: IfClauseDecorator
  
  def name
    model.name || 'New'
  end
end
