Rails.application.routes.draw do
  resources :notebooks

  scope ':notebook', defaults: { notebook: "journal" } do
    resources :entries
    get '/timeline', to: "timeline#index", as: :timeline
    get '/timeline/search', to: "timeline#search", as: :search
    get '/calendar', to: "calendar#monthly", as: :calendar
    get '/calendar/:date', to: "calendar#daily", as: :calendar_daily
  end

  root to: "timeline#index"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
