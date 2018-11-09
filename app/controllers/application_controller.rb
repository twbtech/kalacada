class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  before_action :check_access
  def check_access
    redirect_to login_path if !session[:logged_in] && controller_name != 'sessions'
  end
end
