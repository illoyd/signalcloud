module ApplicationHelper

  def headings(heading, subheading = nil, icon = nil)
    content_for :title, heading
    content_for :heading, heading
    content_for :subheading, subheading
    content_for :heading_icon, icon
  end
  
  def can_buy_phone_number?(organization)
    organization.try(:ready?) && can?(:buy_phone_number, organization)
  end
  
  def can_start_conversation?(organization)
    organization.try(:ready?) && can?(:start_conversation, organization)
  end

  def navigation_list( entries = [], options = {} )
    render partial: 'layouts/navlist', object: entries, locals: { options: options }
  end
  
  def dropdown_list( label, entries = [], options = {} )
    entries.select! { |entry| entry.fetch(:if, true) }
    render partial: 'layouts/dropdown', object: entries, locals: { label: label, options: options }
  end
  
  def split_dropdown_list( entries = [], options = {} )
    entries.select! { |entry| entry.fetch(:if, true) }
    render partial: 'layouts/splitdropdown', object: entries, locals: { options: options } unless entries.empty?
  end
  
  ##
  # Form helper for detecting if an error has occured with a field
  def has_error(object, attribute)
    object.try(:errors).try(:[], attribute).try(:empty?) ? {} : { class: 'has-error' }
  end
  
  ##
  # Create a font-awesome icon
  def icon( kind = :blank, options = {} )
    kind = ICONS.fetch(kind, kind.to_s.gsub(/_/, '-'))
    options[:class] = [ 'fa', "fa-#{kind}", options[:class] ].compact
    content_tag(:i, '', options)
  end
  
  ##
  # Prefix a string with an icon
  def iconify(label, icon, options = {})
    "#{ icon(icon, options) } #{ label }".strip.html_safe
  end

  ##
  # Create a label
  def llabel(text, kind = :default)
    content_tag(:span, text, class: [ 'label', "label-#{ kind }" ].compact)
  end

  def humanize_phone_number( number )
    return humanize_phone_number(number.phone_number) if number.is_a? ::MiniPhoneNumber
    return humanize_phone_number(number.number) if number.is_a? ::PhoneNumber
    number.nil? ? nil : Country.format_international_phone_number(number)

    rescue
      number
  end
  
  def flag_icon_for(object, size = nil)
    country = object.try(:country) || object
    flag_icon(country, size)
  end
  
  def flag_icon(country = nil, size = nil)
    country = (Country[country] || country || 'global') unless country.is_a?(Country)
    size  ||= 'md'
    
    country_name   = country.try(:name)    || 'Global'
    country_alpha2 = (country.try(:alpha2) || 'global').downcase

    #image_tag 'flags/%s/%s.png' % [size.downcase, country.downcase], alt: country_name, title: country_name, style: 'vertical-align: bottom'
    content_tag :span, '', class: ['flag', "flag-#{size.downcase}", "fl-#{country_alpha2}"], title: country_name, alt: country_name
  end
  
  def country_name_for(object)
    country = object.try(:country) || object
    country = (Country[country] || country || 'global') unless country.is_a?(Country)
    country.try(:name) || 'Global'
  end
  
  def progress_bar(percentage, kind=nil, label=nil)
    style = kind.present? ? "progress-bar-#{ kind }" : nil
    content_tag :div, '', {
      class: [ "progress-bar", style ].compact,
      role: "progressbar",
      'aria-valuenow' => percentage.to_i,
      'aria-valuemin' => "0",
      'aria-valuemax' => "100",
      style: "width: #{ percentage.to_i }%"
    }
  end
  
  def section_page?(section)
    content_for(:page_section) == section
  end
  
  def dashboard_page?
    section_page?('dashboard')
  end
  
  def stencil_page?
    section_page?('stencils')
  end
  
  def conversation_page?
    section_page?('conversations')
  end
  
  def phone_book_page?
    section_page?('phone_books')
  end
  
  def ledger_entry_page?
    section_page?('ledger_entries')
  end
  
  def phone_number_page?
    section_page?('phone_numbers')
  end
  
  def user_page?
    section_page?('users')
  end
  
  def conversation_state_tag( state )
    state = state.workflow_state if state.respond_to? :workflow_state
    label = state.to_s
    klass = case state.to_sym
      when :confirming, :confirmed
        :confirmed
      when :denying, :denied
        :denied
      when :failing, :failed
        :failed
      when :expiring, :expired
        :expired
      when :asking
        :asking
      when :asked
        :asked
      when :receiving, :received
        :received
      when :draft
        :draft
      when :errored
        :error
      end
    icon = icon(klass)
    "<span class='label label-#{klass}'>#{icon} #{label}</span>".html_safe
  end
  
  def warning_label( msg )
    content_tag(
      :span,
      iconify('Hey!', :warning),
      class: 'label label-warning has-tooltip', rel: 'tooltip', data: { toggle: 'tooltip', title: msg }
    )
  end

  # A simple way to show error messages for the current devise resource. If you need
  # to customize this method, you can either overwrite it in your application helpers or
  # copy the views to your application.
  #
  # This method is intended to stay simple and it is unlikely that we are going to change
  # it to add more behavior or options.
  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t("errors.messages.not_saved",
                      :count => resource.errors.count,
                      :resource => resource.class.model_name.human.downcase)

    html = <<-HTML
    <div id="error">
      <strong>#{sentence}</strong>
      <ul>#{messages}</ul>
    </div>
    HTML

    html.html_safe
  end

  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_for(user, size = nil, options={} )
    gravatar_id = Digest::MD5::hexdigest(user.email.chomp.downcase)
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?d=retro"
    gravatar_url += "&size=#{size}" unless size.nil?

    options = { alt: user.nickname, class: "gravatar" }.merge options
    options[:height] = size unless size.nil?
    options[:width] = size unless size.nil?

    image_tag( gravatar_url, options )
  end
  
  def checkmark_for( value, options={} )
    icon( 'check', options ) if value
  end
  
  def currency_for( value, country='US', symbol='$' )
    html = '<small>%s%s</small> %0.4f' % [ country, symbol, value ]
    html.html_safe
  end
  
  def display_name_for(item)
    return case item
      when Conversation
        "Conversation ##{ item.id } (#{ humanize_phone_number(item.customer_number) })"
      when PhoneNumber
        humanize_phone_number(item.number)
      when Message
        display_name_for(item.conversation)
      else
        item.class.name
    end
  end
  
  def display_icon_for(item)
    return case item
      when Message
        display_icon_for(item.conversation)
      else
        item.class.name.pluralize.underscore
    end
  end
  
  def display_name_and_icon_for(item)
    iconify( display_name_for(item), display_icon_for(item) )
  end

  def supported_countries(use_beta = false)
    countries = use_beta ? Twilio::SUPPORTED_COUNTRIES_BETA : Twilio::SUPPORTED_COUNTRIES
    countries.map { |alpha2| Country[alpha2] }.sort_by(&:name)
  end
  
  def supported_countries_local(use_beta = false)
    countries = use_beta ? Twilio::SUPPORTED_COUNTRIES_LOCAL_BETA : Twilio::SUPPORTED_COUNTRIES_LOCAL
    countries.map { |alpha2| Country[alpha2] }.sort_by(&:name)
  end
  
  def supported_countries_mobile(use_beta = false)
    countries = use_beta ? Twilio::SUPPORTED_COUNTRIES_MOBILE_BETA : Twilio::SUPPORTED_COUNTRIES_MOBILE
    countries.map { |alpha2| Country[alpha2] }.sort_by(&:name)
  end
  
  def map_for_coordinates(lat, lon, options = {})
    default_options = {
      src:         URI::HTTPS.build(
                     host: "www.google.com",
                     path: "/maps/embed/v1/view",
                     query: { center: "#{ lat },#{ lon }", maptype: 'satellite', zoom: 12, key: Rails.application.secrets.google_maps_key }.to_query ),
      width:       '100%',
      height:      '250',
      frameborder: 0,
      style:       'border: 0'
    }
    content_tag(:iframe, '', options.merge(default_options))
  end
  
end
