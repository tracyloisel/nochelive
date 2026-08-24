Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
  post "join", to: "joins#create"
  resources :wards, only: [ :new, :create ]
  get "ramas/entrar", to: "ward_gates#show", as: :ward_gate
  post "ramas/entrar", to: "ward_gates#create"
  resources :game_sessions, only: [ :new, :create ] do
    get :created, on: :member
  end

  scope "/s/:session_code", as: :night do
    get "name", to: "players#new"
    post "players", to: "players#create"
    get "play", to: "play#show"
    get "watch", to: "watch#show"
    post "presence", to: "presences#create"
    resources :teams, only: [ :create ] do
      resources :memberships, only: [ :create ]
    end
    resources :round_runs, only: [] do
      resource :buzz, only: [ :create ]
      resource :answer, only: [ :create ]
      resource :tap, only: [ :create ]
      resource :pose_hold, only: [ :create ]
      resource :freeze, only: [ :create ]
      resource :vote, only: [ :create ]
    end
    post "chests/:id", to: "chests#create", as: :chest
    post "rank_up", to: "rank_ups#create", as: :rank_up
  end

  get "/p/:session_code", to: "presenter/gates#show", as: :presenter_gate
  post "/p/:session_code", to: "presenter/gates#create"
  get "/p/:session_code/console", to: "presenter/consoles#show", as: :presenter_console
  post "/p/:session_code/start", to: "presenter/nights#start", as: :presenter_start
  post "/p/:session_code/pause", to: "presenter/nights#pause", as: :presenter_pause
  post "/p/:session_code/resume", to: "presenter/nights#resume", as: :presenter_resume
  post "/p/:session_code/finish", to: "presenter/nights#finish", as: :presenter_finish
  post "/p/:session_code/rounds/:id/crown", to: "presenter/nights#crown", as: :presenter_crown
  post "/p/:session_code/rounds/:id/open", to: "presenter/round_runs#open", as: :presenter_open_round
  post "/p/:session_code/rounds/:id/lock", to: "presenter/round_runs#lock", as: :presenter_lock_round
  post "/p/:session_code/rounds/:id/reveal", to: "presenter/round_runs#reveal", as: :presenter_reveal_round
  post "/p/:session_code/rounds/:id/complete", to: "presenter/round_runs#complete", as: :presenter_complete_round
  post "/p/:session_code/people/link", to: "presenter/people#create", as: :presenter_people_link
  post "/p/:session_code/people/:id/link", to: "presenter/people#create", as: :presenter_person_link
  post "/p/:session_code/scores", to: "presenter/score_events#create", as: :presenter_scores
end
