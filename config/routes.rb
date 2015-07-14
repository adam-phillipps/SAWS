Rails.application.routes.draw do
  # users get authed before being allowed further
  root 'smash_clients#index'

  # urls /smash_clients/:id/contract
  resources :smash_clients do
      resources :contracts
  end

  #devise_for :users
  devise_for :users, controllers: { registrations: "users/registrations" }

  post 'add_service', to: 'smash_clients#add_service' # this needs to come from the smash_client index page link "add service", arrive at the add_service.html.haml
  # then be able to create a new contract attached to the smash_client that generated the request

  get 'stop', to: 'contracts#stop_instance'

  get 'terminate', to: 'contracts#terminate_instance'

  get 'users', to: 'users#index', as: :user

  get 'users', to: 'users#edit', as: :edit_user

end