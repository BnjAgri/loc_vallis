Rails.application.routes.draw do
  post "stripe/webhook", to: "stripe_webhooks#create"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope "(:locale)", locale: /fr|en/ do
    devise_for :owners, skip: [:sessions]
    devise_for :users, skip: [:sessions]

    get "login", to: "unified_sessions#new"
    post "login", to: "unified_sessions#create"
    delete "logout", to: "unified_sessions#destroy"

    root to: "rooms#index"

    resources :rooms, only: %i[index show] do
      resources :bookings, only: %i[new create]
    end

    resources :bookings, only: %i[index show] do
      resources :messages, only: %i[create]
      resources :reviews, only: %i[create]
      member do
        post :checkout
        patch :cancel
      end
    end

    get "inbox", to: "inbox#index"

    namespace :admin do
      get "inbox", to: "inbox#index"

      resources :rooms, only: %i[index show new create edit update destroy] do
        resources :opening_periods, only: %i[create edit update destroy]
      end

      resources :bookings, only: %i[index show] do
        member do
          patch :approve
          patch :decline
          patch :cancel
          post :refund
        end
      end
    end
  end
end
