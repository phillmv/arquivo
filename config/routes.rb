Rails.application.routes.draw do
  resources :notebooks

  scope ':notebook', defaults: { notebook: "journal" } do
    get '/timeline', to: "timeline#index", as: :timeline
    get '/agenda', to: "timeline#agenda", as: :agenda
    get '/timeline/search', to: "timeline#search", as: :search
    get '/calendar', to: "calendar#monthly", as: :calendar
    get '/calendar/weekly', to: "calendar#weekly", as: :calendar_weekly
    get '/calendar/:date', to: "calendar#daily", as: :calendar_daily

    get "/settings", to: "settings#index", as: :settings
    post "/settings/add_calendar", to: "settings#add_calendar", as: :add_calendar

    post "/", to: "entries#create", as: :create_entry
    get "/", to: redirect("/%{notebook}/timeline")
    get '/entries', to: "entries#index"
    get '/save', to: "entries#save_bookmark"
    post "/create_or_update", to: "entries#create_or_update", as: :create_or_update_entry
    patch "/create_or_update", to: "entries#create_or_update"
    resources :entries, path: "/" do
      member do
        get "files/:filename", to: "entries#files", as: :file_path
      end
    end
  end

  root to: "timeline#index"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
