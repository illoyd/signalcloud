class PhoneNumberDecorator < ApplicationDecorator
  delegate_all
  
  decorates_association :phone_books, with: PhoneBookDecorator
  decorates_association :phone_book_entries, with: PhoneBookEntryDecorator

  def display_name
    Country.format_international_phone_number(number)
  end
  
  def country
    Country.find_country_by_phone_number(number)
    #country = (Country[country] || country || 'global') unless country.is_a?(Country)
    #country.try(:name) || 'Global'
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

  def buy_button
    h.link_to(h.icon(:purchase), [:purchase, object], class: 'btn btn-xs btn-success', method: :post) if h.policy(object).purchase?
  end

  def release_button
    h.link_to(h.icon(:release), [:release, object], class: 'btn btn-xs btn-danger', method: :delete) if h.policy(object).release?
  end

end
