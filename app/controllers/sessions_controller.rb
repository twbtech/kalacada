class SessionsController < ApplicationController
  def login
    respond_to do |format|
      format.html do
        if session[:logged_in]
          redirect_to dashboards_path
        elsif request.post?
          if params[:username] == TEST_USERNAME && params[:password] == TEST_PASSWORD
            session[:logged_in] = true
            redirect_to dashboards_path
          else
            redirect_to login_path, flash: { error: 'Incorrect username or password' }
          end
        end
      end
    end
  end

  def logout
    reset_session
    redirect_to login_path
  end
end
