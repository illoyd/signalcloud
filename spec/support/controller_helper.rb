module ControllerHelper
  def signin_user( user )
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user
  end

  def sign_in_user(user)
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user.confirm! # or set a confirmed_at inside the factory. Only necessary if you are using the "confirmable" module
      sign_in user
    end
  end
end