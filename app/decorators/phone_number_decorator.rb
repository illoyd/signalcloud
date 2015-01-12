class PhoneNumberDecorator < ApplicationDecorator
  delegate_all
  
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


#   def flag_icon_for(object, size = nil)
#     country = object.try(:country) || object
#     flag_icon(country, size)
#   end
#   
#   def flag_icon(country = nil, size = nil)
#     country = (Country[country] || country || 'global') unless country.is_a?(Country)
#     size  ||= 'md'
#     
#     country_name   = country.try(:name)    || 'Global'
#     country_alpha2 = (country.try(:alpha2) || 'global').downcase
# 
#     #image_tag 'flags/%s/%s.png' % [size.downcase, country.downcase], alt: country_name, title: country_name, style: 'vertical-align: bottom'
#     content_tag :span, '', class: ['flag', "flag-#{size.downcase}", "fl-#{country_alpha2}"], title: country_name, alt: country_name
#   end
#   
#   def country_name_for(object)
#     country = object.try(:country) || object
#     country = (Country[country] || country || 'global') unless country.is_a?(Country)
#     country.try(:name) || 'Global'
#   end
