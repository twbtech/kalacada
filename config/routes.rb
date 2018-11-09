Rails.application.routes.draw do
  root to: 'dashboards#index'

  resources :dashboards, only: [:index] do
    collection do
      get :projects
    end
  end

  match '/login', to: 'sessions#login', via: [:get, :post], as: 'login'
  match '/logout', to: 'sessions#logout', via: :get, as: 'logout'
end
