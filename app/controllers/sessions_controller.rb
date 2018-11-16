class SessionsController < ApplicationController
  def login
    respond_to(&:html)
  end

  def logout
    reset_session
    redirect_to login_path
  end
end
