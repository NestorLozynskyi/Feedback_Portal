Rails.application.routes.draw do
  root "suggestions#index"

  resource :session, only: %i[new create destroy]
  get "signup" => "registrations#new", as: :new_registration
  post "signup" => "registrations#create", as: :registration
  resources :passwords, param: :token, only: %i[new create edit update]

  resources :suggestions do
    resource :vote, only: %i[create destroy]
    resources :comments, only: %i[create edit update destroy] do
      member do
        patch :hide
        patch :unhide
      end
    end
    member do
      patch :status
      patch :hide
      patch :unhide
    end
  end
  get "roadmap" => "roadmap#show", as: :roadmap

  namespace :admin do
    resources :categories, only: %i[index create edit update destroy]
    resources :users, only: :index do
      member do
        patch :block
        patch :unblock
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
