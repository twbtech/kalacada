def login(role)
  logout
  session[:logged_in_user] = { 'id' => 12_345, 'display_name' => 'Alex' }

  allow_any_instance_of(Solas::User).to receive(:load_role).and_return(role)
end

def logout
  session[:logged_in_user] = nil
end
