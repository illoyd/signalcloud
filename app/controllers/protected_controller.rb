class ProtectedController < ApplicationController
  # Require user
  before_action :authenticate_user!
  
  # Include Pundit functions and validations
  include Pundit
  after_action :verify_authorized, :except => :index
  after_action :verify_policy_scoped, :only => :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  decorates_assigned :teams, :team

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

end
