Rails.application.routes.draw do
  namespace :admin_api, path: "internal/admin", defaults: { format: :json } do
    get :stats, to: "stats#index"
    get :people_seen_today, to: "presences#index"
    resources :wards, only: [ :index, :show ], param: :code do
      post :rotate_presenter_token, on: :member
      get :stats, on: :member
      resources :nights, only: [ :create, :update ], param: :session_code, controller: "nights"
    end
    post "profile_merges/preview", to: "profile_merges#preview"
    post "profile_merges", to: "profile_merges#create"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "sitemap.xml", to: "seo#sitemap", defaults: { format: :xml }, as: :sitemap
  get "llms.txt", to: "agent_discovery#llms", defaults: { format: :text }, as: :llms
  get "agent/:locale/index.md", to: "agent_discovery#page", defaults: { slug: "", format: :md },
      constraints: { locale: /es|fr|en|pt-br/ }
  get "agent/:locale/*slug", to: "agent_discovery#page", defaults: { format: :md },
      constraints: ->(request) { request.path.end_with?(".md") && request.params[:locale].match?(/\A(?:es|fr|en|pt-br)\z/) }
  post "migration/identity", to: "identity_transfers#create", as: :identity_transfer
  get "migration/identity/claim", to: "identity_transfers#claim", as: :identity_transfer_claim
  post "migration/identity/merge", to: "identity_transfers#merge", as: :identity_transfer_merge

  root "street_hub#index"
  get "public/:public_token", to: "public#show", as: :night_public
  post "public/:public_token/rounds/:round_run_id/response", to: "audience_responses#create", as: :night_public_response
  post "public/:public_token/rounds/:round_run_id/reaction", to: "audience_reactions#create", as: :night_public_reaction
  get "jugar", to: "street_plays#show", as: :jugar
  get "mapa", to: "street_hub#map", as: :street_map
  post "packs/:pack_id", to: "street_pack_starts#create", as: :street_pack_start
  get "desafio/:token", to: "street_challenges#show", as: :street_challenge
  post "desafio/:token", to: "street_challenges#accept", as: :street_challenge_accept
  post "desafio/:token/decline", to: "street_challenges#decline", as: :street_challenge_decline
  get "desafios", to: "street_challenges#index", as: :street_challenges
  post "desafios", to: "street_challenges#create"
  post "viral-events", to: "viral_events#create", as: :viral_events
  post "quiz/:quiz_run_id/answers", to: "quiz_answers#create", as: :quiz_answers
  post "quiz/:quiz_run_id/advance", to: "quiz_advances#create", as: :quiz_advance
  post "quiz/:quiz_run_id/rewind", to: "quiz_rewinds#create", as: :quiz_rewind
  post "quiz/:quiz_run_id/jump", to: "quiz_jumps#create", as: :quiz_jump
  post "quiz/:quiz_run_id/expire", to: "quiz_expires#create", as: :quiz_expire
  get "ficha", to: "street_profiles#show", as: :street_profile
  post "ficha", to: "street_profiles#create"
  patch "ficha", to: "street_profiles#update"
  post "ficha/fusion", to: "street_profile_merges#create", as: :street_profile_merge
  get "quien", to: redirect("/ficha")
  post "rama", to: "street_ward_picks#create", as: :street_ward_pick
  get "camino", to: redirect("/mapa#historial")
  get "camino/historial", to: redirect("/mapa#historial")
  get "home", to: redirect("/"), as: :legacy_home
  get "liga", to: "street_leaderboards#show", as: :street_leaderboard
  post "presence", to: "street_presences#create", as: :street_presence
  post "join", to: "joins#create"
  patch "locale", to: "locales#update"
  get "nosotros", to: "ward_adds#show", as: :about
  get "iglesia", to: "pages#church", as: :church
  get "iglesia/misioneros", to: "pages#church_meet", as: :church_meet
  get "iglesia/creencias", to: "pages#church_beliefs", as: :church_beliefs
  get "iglesia/mision", to: "pages#church_missionaries", as: :church_missionaries
  get "iglesia/adorar", to: "pages#church_worship", as: :church_worship
  get "videos", to: "church_videos#index", as: :church_videos
  get "videos/miniatures/:id", to: "church_video_thumbnails#show", as: :church_video_thumbnail,
      constraints: { id: /[A-Za-z0-9_-]{11}/ }
  get "legal", to: "pages#legal", as: :legal
  get "privacidad", to: "pages#privacy", as: :privacy
  get "cifras", to: "pages#stats", as: :platform_stats
  get "pulso", to: "street_pulses#show", as: :street_pulse
  get "buscar", to: "searches#show", as: :search
  get ":locale/:church_section(/:church_page)",
      to: "pages#localized_church",
      as: :localized_church,
      constraints: {
        locale: /es|fr|en|pt-br/,
        church_section: /iglesia-de-jesucristo|eglise-de-jesus-christ|church-of-jesus-christ|igreja-de-jesus-cristo/
      }
  get ":locale/:scripture_section/:book/:chapter/:verse",
      to: "scriptures#passage",
      as: :scripture_passage,
      constraints: {
        locale: /es|fr|en|pt-br/,
        scripture_section: /bible|biblia|libro-de-mormon|livre-de-mormon|book-of-mormon|livro-de-mormon|doctrina-y-convenios|doctrine-et-alliances|doctrine-and-covenants|doutrina-e-convenios/,
        chapter: /[1-9]\d*/,
        verse: /[1-9]\d*(?:-[1-9]\d*)?/
      }
  get ":locale/:scripture_section/:book/:chapter",
      to: "scriptures#chapter",
      as: :scripture_chapter,
      constraints: {
        locale: /es|fr|en|pt-br/,
        scripture_section: /bible|biblia|libro-de-mormon|livre-de-mormon|book-of-mormon|livro-de-mormon|doctrina-y-convenios|doctrine-et-alliances|doctrine-and-covenants|doutrina-e-convenios/,
        chapter: /[1-9]\d*/
      }
  get ":locale/:scripture_section/:book",
      to: "scriptures#book",
      as: :scripture_book,
      constraints: {
        locale: /es|fr|en|pt-br/,
        scripture_section: /bible|biblia|libro-de-mormon|livre-de-mormon|book-of-mormon|livro-de-mormon|doctrina-y-convenios|doctrine-et-alliances|doctrine-and-covenants|doutrina-e-convenios/
      }
  get ":locale/:ward_section/:slug",
      to: "ward_profiles#show",
      as: :localized_ward_profile,
      constraints: {
        locale: /es|fr|en|pt-br/,
        ward_section: /santos-de-los-ultimos-dias|saints-des-derniers-jours|latter-day-saints|santos-dos-ultimos-dias/
      }
  get ":locale", to: "discovery#show", as: :discovery_home, constraints: { locale: /es|fr|en|pt-br/ }
  get ":locale/*slug", to: "discovery#show", as: :discovery, constraints: { locale: /es|fr|en|pt-br/ }, format: false
  post "escrituras/lectures", to: "scripture_reads#create", as: :scripture_reads
  post "escrituras/surlignages", to: "scripture_highlights#create", as: :scripture_highlights
  delete "escrituras/surlignages/:id", to: "scripture_highlights#destroy", as: :scripture_highlight
  get "escrituras/*study", to: "scriptures#show", as: :scripture, format: false
  get "parole", to: "study_programs#show", as: :study_program
  get "parole/historique", to: "study_histories#show", as: :study_history
  get "parole/paroisse/:ward_code", to: "study_communities#show", as: :study_community
  get "parole/semaines/:id", to: "study_units#show", as: :study_unit
  post "parole/semaines/:study_unit_id/commencer", to: "study_runs#create", as: :study_run_start
  get "parole/parcours/:id", to: "study_runs#show", as: :study_run
  post "parole/parcours/:study_run_id/reponses", to: "study_answers#create", as: :study_run_answers
  post "parole/parcours/:study_run_id/suivant", to: "study_advances#create", as: :study_run_advance
  resources :wards, only: [ :new, :create ]
  get "ramas/anadir", to: "ward_adds#show", as: :add_ward
  get "ramas/entrar", to: "ward_gates#show", as: :ward_gate
  post "ramas/entrar", to: "ward_gates#create"
  post "ramas/elegir", to: "ward_enters#create", as: :enter_ward
  get "ramas/fichas", to: "fichas#index", as: :ward_fichas
  get "ramas/fichas/:id", to: "fichas#show", as: :ward_ficha
  patch "ramas/fichas/:id", to: "fichas#update"
  post "ramas/fichas/:id/merge", to: "fichas#merge", as: :ward_ficha_merge
  get "ramas/:code/n/:session_code", to: "ward_memories#show", as: :ward_memory
  get "ramas/:code/liga", to: "street_leaderboards#show", as: :ward_leaderboard
  get "ramas/:code", to: "ward_profiles#show", as: :ward_profile
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
      resource :cheer, only: [ :create ]
      resource :forward, only: [ :create ], controller: "round_forwards"
      resource :tap, only: [ :create ]
      resource :pose_hold, only: [ :create ]
      resource :freeze, only: [ :create ]
      resource :vote, only: [ :create ]
    end
    post "chests/:id", to: "chests#create", as: :chest
    post "rank_up", to: "rank_ups#create", as: :rank_up
    patch "locale", to: "locales#update"
  end

  get "/p/:session_code", to: "presenter/gates#show", as: :presenter_gate
  post "/p/:session_code", to: "presenter/gates#create"
  get "/p/:session_code/claim", to: "presenter/claims#show", as: :presenter_claim
  post "/p/:session_code/claim", to: "presenter/claims#create"
  post "/p/:session_code/claims/:id/resolve", to: "presenter/claims#resolve", as: :presenter_claim_resolve
  get "/p/:session_code/console", to: "presenter/consoles#show", as: :presenter_console
  post "/p/:session_code/start", to: "presenter/nights#start", as: :presenter_start
  post "/p/:session_code/pause", to: "presenter/nights#pause", as: :presenter_pause
  post "/p/:session_code/resume", to: "presenter/nights#resume", as: :presenter_resume
  post "/p/:session_code/finish", to: "presenter/nights#finish", as: :presenter_finish
  post "/p/:session_code/rounds/:id/crown", to: "presenter/nights#crown", as: :presenter_crown
  post "/p/:session_code/rounds/:id/open", to: "presenter/round_runs#open", as: :presenter_open_round
  post "/p/:session_code/rounds/:id/peel", to: "presenter/round_runs#peel", as: :presenter_peel_round
  post "/p/:session_code/rounds/:id/lock", to: "presenter/round_runs#lock", as: :presenter_lock_round
  post "/p/:session_code/rounds/:id/reveal", to: "presenter/round_runs#reveal", as: :presenter_reveal_round
  post "/p/:session_code/rounds/:id/complete", to: "presenter/round_runs#complete", as: :presenter_complete_round
  post "/p/:session_code/people/link", to: "presenter/people#create", as: :presenter_people_link
  post "/p/:session_code/people/:id/link", to: "presenter/people#create", as: :presenter_person_link
  post "/p/:session_code/scores", to: "presenter/score_events#create", as: :presenter_scores
  get "/p/:session_code/lista", to: "presenter/rosters#show", as: :presenter_roster
  post "/p/:session_code/missionaries", to: "presenter/missionaries#create", as: :presenter_missionaries
  delete "/p/:session_code/missionaries/:id", to: "presenter/missionaries#destroy", as: :presenter_missionary
  get "/p/:session_code/fichas", to: "presenter/fichas#index", as: :presenter_fichas
  get "/p/:session_code/fichas/:id", to: "presenter/fichas#show", as: :presenter_ficha
  patch "/p/:session_code/fichas/:id", to: "presenter/fichas#update"
  post "/p/:session_code/fichas/:id/merge", to: "presenter/fichas#merge", as: :presenter_ficha_merge
  patch "/p/:session_code/people/:person_id/locale", to: "presenter/locales#update", as: :presenter_person_locale
  patch "/p/:session_code/players/:player_id/locale", to: "presenter/locales#update", as: :presenter_player_locale
end
