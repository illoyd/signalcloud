class StencilDecorator < ApplicationDecorator
  delegate_all

  decorates_association :phone_book, with: PhoneBookDecorator
  
  def name
    model.name || 'New'
  end
end
