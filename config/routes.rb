Rails.application.routes.draw do
  resources :notebooks

  if Arquivo.static?
    # change the scope in a separate env
    # but what about the path helpers? won't they error out from not having owner
    # (didn't you rewrite all of them recently?)
    # slash copy the templates as opposed to trying to fix them. benefit is you can run in that mode
    # maybe a StaticGen controller of its own
    # i only really have like 3 types in this system? post{note,bookmark,calendar}, tag, contact?
    #
    # scope :notebook do
    #   get / to timeline
    #   get /page/:number
    #   get /tags
    #   get /tags/:tag
    #   get /bookmarks
    #   get /bookmarks/:bookmark
    #   get /calendar
    #   get /index
    #   get /index/:word
    #   get /:identifier
    #   get /:identifier/files/:filename
    #
    # that's easy dude.

    get '/calendar', to: "static_site/calendar#monthly", as: :calendar
    get '/calendar/weekly', to: "static_site/calendar#weekly", as: :calendar_weekly
    get '/calendar/daily/(:date)', to: "static_site/calendar#daily", as: :calendar_daily

    get '/tags/', to: "static_site/timeline#tags", as: :tags
    get '/tags/:query', to: "static_site/timeline#tag", as: :tag
    get '/contacts/', to: "static_site/timeline#contacts", as: :contacts
    get '/contacts/:query', to: "static_site/timeline#contact", as: :contact
    get '/page/:page', to: "static_site/timeline#index"

    # this is a hack to preserve routing of previous attached files
    # whose url will refer /owner/notebook/identifier/files/filename
    scope ':owner' do
      # lambda used exclusively to handle ActiveStorage urls while mounting the whole app
      # on a /user subdirectory, cos we've defined the ActiveStorage route prefix to be
      # /user/_/
      scope ':notebook', constraints: lambda { |req| req.path.split("/")[2] != "_" } do
        get "/*id/files/:filename", to: "entries#files", as: :files_entry, constraints: { filename: /[^\/]+/ }
      end
    end

    get '/', to: "static_site/timeline#index", as: :timeline

    get "/*id/thread", to: "static_site/entries#show", defaults: { thread: true }, as: :threaded_entry
    get "/*id", to: "static_site/entries#show", as: :entry

    # only here to keep the UrlHelper ticking
    get "/settings", to: "settings#index", as: :settings
    get "/*id/edit", to: "entries#edit", as: :edit_entry
  else

  scope ':owner', defaults: { owner: "owner" } do
    # lambda used exclusively to handle ActiveStorage urls while mounting the whole app
    # on a /user subdirectory, cos we've defined the ActiveStorage route prefix to be
    # /user/_/
    scope ':notebook', defaults: { notebook: "journal" }, constraints: lambda { |req| req.path.split("/")[2] != "_" } do
      get '/', to: "timeline#index", as: :timeline
      get '/page/:page', to: "timeline#index"
      get '/agenda', to: "timeline#agenda", as: :agenda
      get '/timeline/search', to: "timeline#search", as: :search
      post '/timeline/save_search', to: "timeline#save_search", as: :save_search
      delete '/timeline/save_search/:id', to: "timeline#delete_saved_search", as: :delete_saved_search

      get '/review', to: "timeline#review", as: :review
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

      get "_tags/:query", to: "notebooks#tags"
      get "_tags/", to: "notebooks#tags"
      get "_subjects/", to: "notebooks#subjects"
      get "_subjects/:query", to: "notebooks#subjects"

      get "_contacts/:query", to: "notebooks#contacts"
      get "_contacts/", to: "notebooks#contacts"

      put "/update", to: "notebooks#update", as: :update_notebook

      # begin weird entry url fuckery
      # in order to support slashes as valid parts of the url, and not have
      # the url get escaped by the url helper, you have to specify the url as
      # a glob match, i.e. /*param. but when using the `resources` keyword, you
      # cannot specify glob matches, and therefore you also cannot have nice
      # things like "resources do member do get 'foo'"
      #
      # cf https://github.com/rails/rails/issues/14636
      #
      # therefore, we have to do everything by hand, as follows:

      # resources :entries, path: "/" do
      #   member do
            # get "thread", to: "entries#show", defaults: { thread: true }, as: :threaded
            # post "copy/:target_notebook", to: "entries#copy", as: :copy
            # get "files/:filename", to: "entries#files", as: :files, constraints: { filename: /[^\/]+/ }
            # post "direct_upload", to: "active_storage/direct_uploads#create", as: :direct_upload
            get "/*id/thread", to: "entries#show", defaults: { thread: true }, as: :threaded_entry
            post "/*id/copy/:target_notebook", to: "entries#copy", as: :copy_entry
            get "/*id/files/:filename", to: "entries#files", as: :files_entry, constraints: { filename: /[^\/]+/ }
            post "/*id/direct_upload", to: "active_storage/direct_uploads#create", as: :direct_upload_entry
      #  end
      #  # normal resources stuff but with glob matches:
      get    "/new",      to: "entries#new",  as: :new_entry
      get    "/*id/edit", to: "entries#edit", as: :edit_entry
      get    "/*id",      to: "entries#show", as: :entry
      post   "/",         to: "entries#create"
      patch  "/*id",      to: "entries#update"
      put    "/*id",      to: "entries#update"
      delete "/*id",      to: "entries#destroy"
      # end weird entry url fuckery
    end
  end

  root to: "timeline#redirect_to_notebook"
  get ":owner", to: "timeline#redirect_to_notebook"
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
