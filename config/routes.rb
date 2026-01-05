Rails.application.routes.draw do
  devise_for :owners
  devise_for :users
  root to: "pages#home"

  resources :rooms, only: %i[index show] do
    resources :bookings, only: %i[new create]
  end

  resources :bookings, only: %i[index show] do
    resources :messages, only: %i[create]
    member do
      post :checkout
      patch :cancel
    end
  end

  post "stripe/webhook", to: "stripe_webhooks#create"

  namespace :admin do
    resources :bookings, only: %i[index show] do
      member do
        patch :approve
        patch :decline
        patch :cancel
        post :refund
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
