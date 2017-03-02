Rails.application.routes.draw do
  resources :documents, except: [:edit, :update, :show]

	resources :open_layers
	root to: "landing#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
