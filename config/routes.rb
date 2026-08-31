Rails.application.routes.draw do
  namespace :admin_api, path: "internal/admin", defaults: { format: :json } do
    get :stats, to: "stats#index"
    get :people_seen_today, to: "presences#index"
    resources :wards, only: [ :index, :show ], param: :code do
      get :stats, on: :member
      resources :ward_teams, only: [ :create ], controller: "ward_teams"
      resources :nights, only: [ :create, :update ], param: :session_code, controller: "nights"
      post "nights/:session_code/finish", to: "nights#finish", as: :finish_night
      resources :ward_events, only: %i[index show create update] do
        post :publish, on: :member
        post :cancel, on: :member
      end
    end
    post "profile_merges/preview", to: "profile_merges#preview"
    post "profile_merges", to: "profile_merges#create"
    resources :notification_editorials, only: %i[index create update] do
      get :preview, on: :member
      post :approval_preview, on: :member
      post :approve, on: :member
    end
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
  get "jugar", to: "street_plays#show", as: :jugar
  get "mapa", to: "street_hub#map", as: :street_map
  post "packs/:pack_id", to: "street_pack_starts#create", as: :street_pack_start
  get "desafio/:token", to: "street_challenges#show", as: :street_challenge
  post "desafio/:token", to: "street_challenges#accept", as: :street_challenge_accept
  post "desafio/:token/decline", to: "street_challenges#decline", as: :street_challenge_decline
  post "desafio/:token/received", to: "street_challenges#received", as: :street_challenge_received
  post "desafio/:token/opened", to: "street_challenges#opened", as: :street_challenge_opened
  get "desafios", to: "street_challenges#index", as: :street_challenges
  post "desafios", to: "street_challenges#create"
  get "desafios/:id", to: "street_challenges#duel", as: :street_duel, constraints: { id: /\d+/ }
  post "desafios/:id/revanche", to: "street_challenges#rematch", as: :street_duel_rematch, constraints: { id: /\d+/ }
  post "viral-events", to: "viral_events#create", as: :viral_events
  post "quiz/:quiz_run_id/answers", to: "quiz_answers#create", as: :quiz_answers
  post "quiz/:quiz_run_id/advance", to: "quiz_advances#create", as: :quiz_advance
  post "quiz/:quiz_run_id/rewind", to: "quiz_rewinds#create", as: :quiz_rewind
  post "quiz/:quiz_run_id/jump", to: "quiz_jumps#create", as: :quiz_jump
  post "quiz/:quiz_run_id/expire", to: "quiz_expires#create", as: :quiz_expire
  get "ficha", to: "street_profiles#show", as: :street_profile
  post "ficha", to: "street_profiles#create"
  get "jugadores/:player_id/perfil", to: "street_profiles#show", as: :player_profile,
      constraints: { player_id: /\d+/ }
  patch "jugadores/:player_id/perfil", to: "street_profiles#update",
        constraints: { player_id: /\d+/ }
  get "jugadores/:player_id/perfil/respuestas", to: "street_quiz_histories#show", as: :player_quiz_history,
      constraints: { player_id: /\d+/ }
  get "jugadores/:player_id/perfil/publicaciones-del-circulo", to: "scripture_circle_profile_posts#index",
      as: :player_scripture_circle_posts, constraints: { player_id: /\d+/ }
  post "jugadores/:player_id/perfil/fusion", to: "street_profile_merges#create", as: :player_profile_merge,
       constraints: { player_id: /\d+/ }
  get "notifications", to: "notification_settings#show", as: :notification_settings
  get "quien", to: redirect("/ficha")
  post "rama", to: "street_ward_picks#create", as: :street_ward_pick
  get "camino", to: redirect("/mapa#historial")
  get "camino/historial", to: redirect("/mapa#historial")
  get "home", to: redirect("/"), as: :legacy_home
  get "liga", to: "street_leaderboards#show", as: :street_leaderboard
  post "presence", to: "street_presences#create", as: :street_presence
  namespace :notifications do
    resource :subscription, only: [ :create, :destroy ]
    resource :preferences, only: [ :update ]
    resource :prompt_state, only: [ :update ]
    post "deliveries/:id/open", to: "deliveries#open", as: :delivery_open
    post "receipts/:token", to: "receipts#create", as: :receipt
  end
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
  get "bibliotheque", to: "scripture_libraries#show", as: :scripture_library
  get "bibliotheque/recherche", to: "scripture_libraries#search", as: :scripture_library_search
  patch "escrituras/preferencias", to: "scripture_reader_preferences#update", as: :scripture_reader_preferences
  put "escrituras/progreso", to: "scripture_reading_progresses#update", as: :scripture_reading_progress
  post "escrituras/reperes", to: "scripture_marks#create", as: :scripture_marks
  patch "escrituras/reperes/:id", to: "scripture_marks#update", as: :scripture_mark
  delete "escrituras/reperes/:id", to: "scripture_marks#destroy"
  post "escrituras/reperes/:id/restaurar", to: "scripture_marks#restore", as: :restore_scripture_mark
  get "escrituras/cercle", to: "scripture_circles#show", as: :scripture_circle
  post "escrituras/cercle/messages", to: "scripture_circle_posts#create", as: :scripture_circle_posts
  patch "escrituras/cercle/messages/:id", to: "scripture_circle_posts#update", as: :scripture_circle_post
  delete "escrituras/cercle/messages/:id", to: "scripture_circle_posts#destroy"
  put "escrituras/cercle/conversations/:conversation_root_id/vote",
    to: "scripture_circle_conversation_votes#update", as: :scripture_circle_conversation_vote
  put "escrituras/cercle/messages/:post_id/vote",
    to: "scripture_circle_post_votes#update", as: :scripture_circle_post_vote
  post "escrituras/cercle/messages/:post_id/signalements",
    to: "scripture_circle_moderation_reports#create", as: :scripture_circle_moderation_reports
  put "escrituras/cercle/propositions/:proposal_id/vote",
    to: "scripture_circle_moderation_ballots#update", as: :scripture_circle_moderation_ballot
  get "escrituras/cercle/propositions/:proposal_id/resultats",
    to: "scripture_circle_moderation_results#show", as: :scripture_circle_moderation_results
  get "escrituras/cercle/propositions/:proposal_id/historique",
    to: "scripture_circle_moderation_histories#show", as: :scripture_circle_moderation_history
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
  get "ramas/:code/liga", to: "street_leaderboards#show", as: :ward_leaderboard
  get "ramas/:code", to: "ward_profiles#show", as: :ward_profile
  scope "/s/:session_code", as: :night do
    get "/", to: "nights#show"
    get "name", to: "players#new"
    post "players", to: "players#create"
    get "play", to: "play#show"
    resources :teams, only: [] do
      resources :memberships, only: [ :create ]
    end
    patch "locale", to: "locales#update"
  end

end
