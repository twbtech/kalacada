def login
  logout
  session[:logged_in_user] = { 'id' => 12_345, 'display_name' => 'Alex', 'admin' => 'true' }
end

def logout
  session[:logged_in_user] = nil
end
