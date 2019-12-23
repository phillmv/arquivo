Rails.application.routes.draw do
  resources :entries
  get 'timeline', to: "timeline#index", as: :timeline
  get 'timeline/show/:id', to: "timeline#show", as: :timeline_show
  post 'timeline', to: "timeline#search", as: :search

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
