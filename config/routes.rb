# frozen_string_literal: true

Rails.application.routes.draw do
  # Sitio público
  root "home#show"
  resource  :player, only: %i[new create edit update destroy]   # destroy = olvidar la cookie, NO borra el registro
  resources :games,  only: %i[new create show] do
    member do
      post :start
      post :guess
      post :hint
      post :surrender
    end
  end
  get "daily", to: "daily_cryptics#show"
  resource  :streak, only: :show
  resource  :leaderboard, only: :show
  get "como-se-juega", to: "help#show", as: :help
  resource  :chatbot, only: :show

  # Login del backend (generador de autenticación de Rails 8)
  resource  :session
  resources :passwords, param: :token

  # Backend de administración
  namespace :admin do
    root "dashboard#show"
    resources :cryptics, only: %i[index show update]
    resources :syncs,    only: %i[index create]
    resources :type_scores, :difficulty_settings, only: %i[index update]
    resources :users
    resources :players, only: %i[index update] do
      collection { post :reset_leaderboard }
    end
    resources :blocked_names, only: %i[index create destroy]
    resource  :setting, only: %i[edit update]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
