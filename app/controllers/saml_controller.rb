class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:consume]
  skip_after_action :verify_same_origin_request, only: [:consume]

  def index
    settings = Solas::User.saml_settings
    request  = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(settings))
  end

  def consume
    response          = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    response.settings = Solas::User.saml_settings

    if response.is_valid?
      user = Solas::User.from_saml_response(response)

      if user.admin? || user.partner?
        session[:logged_in_user] = user.to_hash
        redirect_to root_path
      else
        redirect_to login_path, flash: { error: "We are sorry, but we couldn't authenticate you. It seems that you don't have permissions to access this site. Please contact administrators and try again." }
      end
    else
      redirect_to login_path, flash: { error: "We are sorry, but we couldn't authenticate you. Something went wrong during authentication process." }
    end
  end
end
