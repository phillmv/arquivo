Rails.application.routes.draw do
  resources :notebooks

  scope ':notebook', defaults: { notebook: "journal" } do
    get '/timeline', to: "timeline#index", as: :timeline
    get '/agenda', to: "timeline#agenda", as: :agenda
    get '/timeline/search', to: "timeline#search", as: :search
    post '/timeline/save_search', to: "timeline#save_search", as: :save_search
    delete '/timeline/save_search/:id', to: "timeline#delete_saved_search", as: :delete_saved_search
    get '/calendar', to: "calendar#monthly", as: :calendar
    get '/calendar/weekly', to: "calendar#weekly", as: :calendar_weekly
    get '/calendar/daily/(:date)', to: "calendar#daily", as: :calendar_daily

    get "/settings", to: "settings#index", as: :settings
    post "/settings/add_calendar", to: "settings#add_calendar", as: :add_calendar

    post "/", to: "entries#create", as: :create_entry
    get "/", to: redirect("/%{notebook}/timeline")
    get '/entries', to: "entries#index"
    get '/save_bookmark', to: "entries#save_bookmark", as: :save_bookmark
    post "/create_or_update", to: "entries#create_or_update", as: :create_or_update_entry
    patch "/create_or_update", to: "entries#create_or_update"

    get "tags/:query", to: "notebooks#tags"
    get "tags/", to: "notebooks#tags"

    get "contacts/:query", to: "notebooks#contacts"
    get "contacts/", to: "notebooks#contacts"

    put "/update", to: "notebooks#update", as: :update_notebook

    resources :entries, path: "/" do
      member do
        post "copy/:target_notebook", to: "entries#copy", as: :copy
        get "files/:filename", to: "entries#files", as: :files, constraints: { filename: /[^\/]+/ }
        post "direct_upload", to: "active_storage/direct_uploads#create", as: :direct_upload
      end
    end
  end

  root to: "timeline#index"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
