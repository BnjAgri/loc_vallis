Rails.application.routes.draw do
  # (generated routes removed; use resources below within locale scope)
  post "stripe/webhook", to: "stripe_webhooks#create"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope "(:locale)", locale: /fr|en/ do
    devise_for :owners, skip: [:sessions]
    devise_for :users, skip: [:sessions]

    # Devise expects session route helpers (e.g. new_user_session_path) even if
    # we use a unified login/logout UI. Provide the standard Devise session
    # routes as aliases to UnifiedSessionsController.
    devise_scope :user do
      get "users/sign_in", to: "unified_sessions#new", as: :new_user_session
      post "users/sign_in", to: "unified_sessions#create", as: :user_session
      delete "users/sign_out", to: "unified_sessions#destroy", as: :destroy_user_session
    end

    devise_scope :owner do
      get "owners/sign_in", to: "unified_sessions#new", as: :new_owner_session
      post "owners/sign_in", to: "unified_sessions#create", as: :owner_session
      delete "owners/sign_out", to: "unified_sessions#destroy", as: :destroy_owner_session
    end

    get "login", to: "unified_sessions#new"
    post "login", to: "unified_sessions#create"
    get "login/email_exists", to: "unified_sessions#email_exists"
    delete "logout", to: "unified_sessions#destroy"

    root to: "rooms#index"

    get "legal", to: "pages#legal"
    get "cgv", to: "pages#cgv"

    resource :profile, only: %i[edit update destroy]

    resources :rooms, only: %i[index show] do
      resources :bookings, only: %i[new create]
    end

    resources :bookings, only: %i[index show] do
      resources :messages, only: %i[create]
      resources :reviews, only: %i[create]
      member do
        post :checkout
        get :payment_success
        get :payment_cancel
        patch :cancel
      end
    end

    get "inbox", to: "inbox#index"

    resources :articles, only: %i[index show new create edit update destroy]

    namespace :admin do
      get "inbox", to: "inbox#index"

      resources :rooms, only: %i[index show new create edit update destroy] do
        member do
          delete "photos/:photo_id", to: "rooms#destroy_photo", as: :photo
        end
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

      resources :clients, only: %i[index show destroy]
    end
  end
end
