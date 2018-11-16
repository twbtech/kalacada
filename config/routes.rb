Rails.application.routes.draw do
  root to: 'dashboards#index'

  resources :dashboards, only: [:index] do
    collection do
      get :capacity
      get :progress
      get :projects
    end
  end

  match '/login', to: 'sessions#login', via: [:get, :post], as: 'login'
  get '/logout', to: 'sessions#logout', as: 'logout'

  get  '/saml',         to: 'saml#index',  as: 'saml_login'
  post '/saml/consume', to: 'saml#consume'
end
