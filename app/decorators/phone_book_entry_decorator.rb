class PhoneBookEntryDecorator < ApplicationDecorator
  delegate_all

  decorates_association :phone_number
  decorates_association :phone_book

  def country
    Country.find_country_by_alpha2(object.country)
  end
  
  def country_name
    country.try(:name)    || 'Global'
  end
  
  def country_alpha2
    (country.try(:alpha2) || 'global').downcase
  end
  
  def country_flag(size = nil)
    size  ||= 'md'
    h.content_tag :span, '', class: ['flag', "flag-#{size.downcase}", "fl-#{country_alpha2}"], title: country_name, alt: country_name
  end
  
  def new_button
    if h.policy(model).new?
      h.link_to h.icon(:new), '#', class: 'btn btn-xs btn-default', data: { toggle: 'modal', target: "#edit_phone_book_entry_#{ model.id || 'new' }" }
    end
  end
  
  def edit_button
    if h.policy(model).edit?
      h.link_to h.icon(:edit), '#', class: 'btn btn-xs btn-default', data: { toggle: 'modal', target: "#edit_phone_book_entry_#{ model.id || 'new' }" }
    end
  end
  
  def edit_modal
    if h.policy(model).edit? && !@edit_modal_printed
      @edit_modal_printed = true
      h.render partial: 'phone_book_entries/edit_modal', object: self, as: :phone_book_entry
    end
  end
  
  def destroy_button
    if h.policy(model).destroy?
      h.link_to h.icon(:delete), '#', class: 'btn btn-xs btn-default', data: { toggle: 'modal', target: "#destroy_phone_book_entry_#{ model.id }" }
    end
  end
  
  def destroy_modal
    if h.policy(model).destroy? && !@destroy_modal_printed
      @destroy_modal_printed = true
      h.render partial: 'phone_book_entries/destroy_modal', object: self, as: :phone_book_entry
    end
  end

end
