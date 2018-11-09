def login
  logout
  session[:logged_in] = true
end

def logout
  session[:logged_in] = nil
end
