class Users::InvitationsController < Devise::InvitationsController

  def build_resource(hash = nil, options = {})
    super
    # raise 'bob'
    self.resource.organization_id = current_inviter.organization_id # if current_inviter
  end

end
