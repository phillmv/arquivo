Rails.application.routes.draw do
  resources :notebooks

  scope ':notebook', defaults: { notebook: "journal" } do
    resources :entries
    get '/timeline', to: "timeline#index", as: :timeline
    get '/timeline/search', to: "timeline#search", as: :search
    get '/calendar', to: "calendar#monthly", as: :calendar
    get '/calendar/:date', to: "calendar#daily", as: :calendar_daily

    get "/settings", to: "settings#index", as: :settings
    post "/settings/add_calendar", to: "settings#add_calendar", as: :add_calendar
  end

  root to: "timeline#index"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
