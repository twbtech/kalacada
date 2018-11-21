class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  before_action :check_access
  def check_access
    redirect_to login_path if !logged_in_user.try(:admin?) && !%w[saml sessions].include?(controller_name) && !Rails.env.development?
  end

  helper_method :logged_in_user
  def logged_in_user
    @logged_in_user ||= Solas::User.from_hash(session[:logged_in_user])
  end
end
