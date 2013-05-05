class Users::InvitationsController < Devise::InvitationsController

  def build_resource(hash = nil, options = {})
    super
    # raise 'bob'
    self.resource.account_id = current_inviter.account_id # if current_inviter
  end

end
