module ApplicationHelper

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
  
  def icon( kind = :blank, options = {} )
    #render partial: 'layouts/icon', object: ICONS.fetch( kind, kind ).to_s, locals: { options: options }
    kind = ICONS.fetch( kind, kind ).to_s

    i_class = options.fetch(:class, '')
    i_class = i_class.concat(' ') if i_class.is_a?(Array)

    i_style = options.fetch(:style, '')
    i_style = i_style.concat(' ') if i_style.is_a?(Array)

    return "<i class='icon-#{kind.to_s} #{i_class}' style='#{i_style}'></i>".html_safe
  end

  def header_icon( kind = :blank, options = {} )
    options = { class: 'header-icon' }.merge options
    icon( kind, options )
  end
  
  def humanize_phone_number( number )
    PhoneTools.humanize( number )
  end
  
  def flag_icon( country='_global', size='medium' )
    country_name = Country[country].name rescue nil
    image_tag 'flags/%s/%s.png' % [size.downcase, country.downcase], alt: country_name, title: country_name, style: 'vertical-align: bottom'
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
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}"
    gravatar_url += "?size=#{size}" unless size.nil?

    options = { alt: user.first_name, class: "gravatar" }.merge options
    options[:height] = size unless size.nil?
    options[:width] = size unless size.nil?

    image_tag( gravatar_url, options )
  end

end
