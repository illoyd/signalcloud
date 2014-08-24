module PhoneNumbersHelper

  def sms_actions()
    [
      [ 'Ignore and do not reply', PhoneNumber::IGNORE ],
      [ 'Reply with message', PhoneNumber::REPLY ]
    ]
  end
  
  def call_actions()
    [
      [ 'Play not-in-service message', PhoneNumber::REJECT ],
      [ 'Play line-is-busy message', PhoneNumber::BUSY ],
      [ 'Answer and speak message', PhoneNumber::REPLY ]
    ]
  end
  
  def status_label_for(phone_number)
    case phone_number.workflow_state
      when 'active'
        llabel(iconify('Active', :active), 'success')
      when 'inactive'
        llabel(iconify('Inactive', :inactive))
      when 'purchasing'
        llabel(iconify('Purchasing', :active), 'warning')
      when 'unpurchasing'
        llabel(iconify('Releasing', :inactive), 'warning')
    end.html_safe
  end
  
  def call_languages()
    PhoneNumber::LANGUAGES.map { |language| [ call_language(language), language ] }
  end
  
  def call_voices()
    PhoneNumber::VOICES.map { |voice| [ call_voice(voice), voice ] }
  end
  
  def call_language(language)
    case language
      when PhoneNumber::AMERICAN_ENGLISH
        'American English'
      when PhoneNumber::BRITISH_ENGLISH
        'British English'
      when PhoneNumber::SPANISH
        'Spanish'
      when PhoneNumber::FRENCH
        'French'
      when PhoneNumber::GERMAN
        'German'
      when PhoneNumber::ITALIAN
        'Italian'
      else
        'other'
    end
  end

  def call_voice(voice)
    case voice
      when PhoneNumber::WOMAN_VOICE
        'female'
      when PhoneNumber::MAN_VOICE
        'male'
      else
        'other'
    end
  end
  
  def supported_countries_navigation_list_fragment
    local  = supported_countries_local_navigation_list_fragment
    mobile = supported_countries_mobile_navigation_list_fragment
    (local + mobile).sort { |a,b| a[:label] <=> b[:label] }
  end

  def supported_countries_local_navigation_list_fragment
    build_supported_countries_navigation_list_fragment(supported_countries_local, 'local')
  end

  def supported_countries_mobile_navigation_list_fragment
    build_supported_countries_navigation_list_fragment(supported_countries_mobile, 'mobile')
  end

  def build_supported_countries_navigation_list_fragment(countries, kind)
    countries.map do |country|
      { label: "#{ country.name }", icon: :phone_numbers, link: new_organization_phone_number_path(@organization, country.alpha2, kind), active: ( params[:country] == country.alpha2 && params[:kind] == kind ) }
    end
  end

end
