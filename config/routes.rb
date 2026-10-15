Rails.application.routes.draw do
  devise_for :users,
             defaults: { format: :json },
             controllers: {
               sessions:  "users/sessions",
               passwords: "users/passwords",
             }

  devise_scope :user do
    post "users/verify_token", to: "users/sessions#verify_token"
  end

  get "users/me", to: "users/me#show"
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :reps, only: [:index, :show] do
    member do
      post :send_documents
      get :recruiting_tree
    end
    collection do
      post :create
      put :update
      delete :destroy
    end
  end

  resources :onboarding_documents, only: [:index, :show] do
    collection do
      post :create
      put :update
      delete :destroy
    end
  end

  resources :recruiters, only: [:index]

  resources :markets, only: [:index] do
    collection do
      post :create
    end
  end

  resources :managed_users, only: [:index] do
    collection do
      post :create
      put :update
      post :reset_password
    end
  end

  resources :permissions, only: [:index] do
    collection do
      post :create
      put :update
      delete :destroy
    end
  end

  resources :roles, only: [:index] do
    collection do
      post :create
    end
  end

  resources :teams, only: [:index] do
    collection do
      post :create
    end
  end
end
