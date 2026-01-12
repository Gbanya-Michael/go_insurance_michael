Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "quotes#new"

  get "/quotes", to: redirect("/")

  resources :quotes, only: [ :new, :create, :show, :update ]

  # Catch-all route for 404 errors - must be last
  # Rails will handle /rails, /assets, etc. before this route is matched
  match "*path", to: "errors#not_found", via: :all
end
