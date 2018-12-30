class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  before_action :check_access
  def check_access
    redirect_to login_path if !%w[saml sessions].include?(controller_name) && !logged_in_user.try(:admin?) && !logged_in_user.try(:partner?)
  end

  helper_method :logged_in_user
  def logged_in_user
    @logged_in_user ||= if Rails.env.development? && ENV['NORMAL_LOG_IN'].to_i == 0
                          Solas::User.from_id(DEVELOPMENT_USER_ID)
                        else
                          Solas::User.from_hash(session[:logged_in_user])
                        end
  end
end
