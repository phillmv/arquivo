Rails.application.routes.draw do
  resources :entries
  get 'timeline', to: "timeline#index", as: :timeline
  post 'timeline', to: "timeline#index"
  get 'timeline/search', to: "timeline#search", as: :search

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
