class UserDecorator < ApplicationDecorator
  delegate_all
  
  decorates_association :memberships, with: MembershipDecorator
  decorates_association :teams,       with: TeamDecorator
  decorates_association :owned_teams, with: TeamDecorator
  
  def email_link
    h.mail_to email
  end
  
  def display_name
    nickname || name || 'Anonymous'
  end

  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_image_tag(size = nil, options={} )
    gravatar_id = Digest::MD5::hexdigest(model.email.chomp.downcase)
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?d=retro"
    gravatar_url += "&size=#{size*2}" unless size.nil?

    options = { alt: display_name, class: "gravatar" }.merge options
    options[:height] = size unless size.nil?
    options[:width] = size unless size.nil?

    h.image_tag( gravatar_url, options )
  end
  
end
