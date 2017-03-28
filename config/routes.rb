Rails.application.routes.draw do
  root to: 'organisations#index'

  resources :groups, only: %w(show create index destroy), param: "slug"

  resources :organisations, only: %w(index)

  resources :content_items, only: %w(index show)
end
