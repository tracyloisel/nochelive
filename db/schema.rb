# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_25_233000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answers", force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.bigint "round_run_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_answers_on_player_id"
    t.index ["round_run_id", "team_id"], name: "index_answers_on_round_run_id_and_team_id", unique: true
    t.index ["round_run_id"], name: "index_answers_on_round_run_id"
    t.index ["team_id"], name: "index_answers_on_team_id"
  end

  create_table "ballots", force: :cascade do |t|
    t.bigint "choice_team_id", null: false
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.bigint "round_run_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["choice_team_id"], name: "index_ballots_on_choice_team_id"
    t.index ["player_id"], name: "index_ballots_on_player_id"
    t.index ["round_run_id", "player_id"], name: "index_ballots_on_round_run_id_and_player_id", unique: true
    t.index ["round_run_id"], name: "index_ballots_on_round_run_id"
    t.index ["team_id"], name: "index_ballots_on_team_id"
  end

  create_table "buzzes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "latency_ms", default: 0, null: false
    t.bigint "player_id", null: false
    t.integer "position", null: false
    t.bigint "round_run_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_buzzes_on_player_id"
    t.index ["round_run_id", "position"], name: "index_buzzes_on_round_run_id_and_position", unique: true
    t.index ["round_run_id", "team_id"], name: "index_buzzes_on_round_run_id_and_team_id", unique: true
    t.index ["round_run_id"], name: "index_buzzes_on_round_run_id"
    t.index ["team_id"], name: "index_buzzes_on_team_id"
  end

  create_table "cheers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "layer_index", null: false
    t.string "mark", default: "fire", null: false
    t.bigint "player_id", null: false
    t.bigint "round_run_id", null: false
    t.bigint "to_player_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_cheers_on_player_id"
    t.index ["round_run_id", "player_id", "layer_index"], name: "index_cheers_on_round_player_layer", unique: true
    t.index ["round_run_id"], name: "index_cheers_on_round_run_id"
    t.index ["to_player_id"], name: "index_cheers_on_to_player_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "presenter_device_digest"
    t.string "presenter_locale", default: "es", null: false
    t.string "presenter_token_digest", null: false
    t.datetime "season_applied_at"
    t.datetime "starts_at", null: false
    t.string "status", default: "lobby", null: false
    t.string "theme_id", null: false
    t.string "theme_title", null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id", null: false
    t.index ["code"], name: "index_game_sessions_active_code", unique: true, where: "((status)::text <> 'finished'::text)"
    t.index ["code"], name: "index_game_sessions_on_code"
    t.index ["starts_at"], name: "index_game_sessions_on_starts_at"
    t.index ["ward_id"], name: "index_game_sessions_on_ward_id"
  end

  create_table "missionaries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_session_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id"], name: "index_missionaries_on_game_session_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "avatar_key", null: false
    t.datetime "created_at", null: false
    t.string "family_name"
    t.string "family_name_key", default: "", null: false
    t.integer "favorite_year", null: false
    t.string "given_name", null: false
    t.string "given_name_key", null: false
    t.bigint "last_ward_team_id"
    t.string "locale", default: "es", null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id", null: false
    t.index ["last_ward_team_id"], name: "index_people_on_last_ward_team_id"
    t.index ["ward_id", "given_name_key", "family_name_key", "avatar_key", "favorite_year"], name: "index_people_on_ficha", unique: true
    t.index ["ward_id"], name: "index_people_on_ward_id"
    t.check_constraint "favorite_year >= 1000", name: "people_favorite_year_four_digits"
  end

  create_table "person_devices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_token", null: false
    t.datetime "last_seen_at"
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["device_token", "person_id"], name: "index_person_devices_on_device_token_and_person_id", unique: true
    t.index ["device_token"], name: "index_person_devices_on_device_token"
    t.index ["person_id"], name: "index_person_devices_on_person_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "avatar_key", null: false
    t.string "client_token", null: false
    t.datetime "created_at", null: false
    t.string "device_token"
    t.bigint "game_session_id", null: false
    t.datetime "last_seen_at"
    t.string "locale", default: "es", null: false
    t.string "location", default: "room", null: false
    t.string "name", null: false
    t.bigint "person_id"
    t.string "role", default: "participant", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id", "client_token"], name: "index_players_on_game_session_id_and_client_token", unique: true
    t.index ["game_session_id", "person_id"], name: "index_players_on_game_session_id_and_person_id", unique: true, where: "(person_id IS NOT NULL)"
    t.index ["game_session_id"], name: "index_players_on_game_session_id"
    t.index ["last_seen_at"], name: "index_players_on_last_seen_at"
    t.index ["person_id"], name: "index_players_on_person_id"
  end

  create_table "pose_holds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "finished", default: false, null: false
    t.integer "held_ms", default: 0, null: false
    t.bigint "player_id", null: false
    t.bigint "round_run_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_pose_holds_on_player_id"
    t.index ["round_run_id", "team_id"], name: "index_pose_holds_on_round_run_id_and_team_id", unique: true
    t.index ["round_run_id"], name: "index_pose_holds_on_round_run_id"
    t.index ["team_id"], name: "index_pose_holds_on_team_id"
  end

  create_table "presenter_blocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.bigint "game_session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id", "device_digest"], name: "index_presenter_blocks_on_game_session_id_and_device_digest", unique: true
    t.index ["game_session_id"], name: "index_presenter_blocks_on_game_session_id"
  end

  create_table "presenter_claims", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.datetime "expires_at", null: false
    t.bigint "game_session_id", null: false
    t.string "name", null: false
    t.datetime "resolved_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id", "device_digest"], name: "index_presenter_claims_on_game_session_id_and_device_digest"
    t.index ["game_session_id"], name: "index_presenter_claims_on_game_session_id"
    t.index ["game_session_id"], name: "index_presenter_claims_one_pending", unique: true, where: "((status)::text = 'pending'::text)"
  end

  create_table "quiz_answers", force: :cascade do |t|
    t.string "choice_key"
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.string "pack_id", null: false
    t.string "question_id", null: false
    t.bigint "quiz_run_id", null: false
    t.datetime "updated_at", null: false
    t.index ["device_digest", "pack_id", "question_id"], name: "idx_on_device_digest_pack_id_question_id_d4c3f03d57"
    t.index ["quiz_run_id", "question_id"], name: "index_quiz_answers_on_quiz_run_id_and_question_id", unique: true
    t.index ["quiz_run_id"], name: "index_quiz_answers_on_quiz_run_id"
  end

  create_table "quiz_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.datetime "ends_at"
    t.datetime "opened_at", null: false
    t.string "pack_id", null: false
    t.bigint "person_id"
    t.integer "position", default: 1, null: false
    t.integer "score", default: 0, null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["device_digest", "person_id", "status"], name: "index_quiz_runs_on_device_person_status"
    t.index ["device_digest", "status"], name: "index_quiz_runs_on_device_digest_and_status"
    t.index ["device_digest"], name: "index_quiz_runs_on_device_digest"
    t.index ["person_id"], name: "index_quiz_runs_on_person_id"
  end

  create_table "reward_grants", force: :cascade do |t|
    t.string "chest_key", null: false
    t.datetime "created_at", null: false
    t.string "reward_key"
    t.string "state", default: "ready", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "chest_key"], name: "index_reward_grants_on_team_id_and_chest_key", unique: true
    t.index ["team_id"], name: "index_reward_grants_on_team_id"
  end

  create_table "round_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_session_id", null: false
    t.integer "layer_index", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "opened_at"
    t.string "phase", default: "pending", null: false
    t.integer "position", null: false
    t.datetime "revealed_at"
    t.datetime "updated_at", null: false
    t.string "yaml_round_id", null: false
    t.index ["game_session_id", "position"], name: "index_round_runs_on_game_session_id_and_position", unique: true
    t.index ["game_session_id", "yaml_round_id"], name: "index_round_runs_on_game_session_id_and_yaml_round_id", unique: true
    t.index ["game_session_id"], name: "index_round_runs_on_game_session_id"
  end

  create_table "score_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_session_id", null: false
    t.string "kind", null: false
    t.integer "points", default: 0, null: false
    t.string "reason", null: false
    t.bigint "round_run_id"
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "xp", default: 0, null: false
    t.index ["game_session_id"], name: "index_score_events_on_game_session_id"
    t.index ["round_run_id", "team_id", "kind"], name: "index_score_events_unique_round_kind", unique: true, where: "((round_run_id IS NOT NULL) AND ((kind)::text = ANY ((ARRAY['correct'::character varying, 'fastest_buzz'::character varying, 'rapid_tap'::character varying, 'participation'::character varying])::text[])))"
    t.index ["round_run_id"], name: "index_score_events_on_round_run_id"
    t.index ["team_id"], name: "index_score_events_on_team_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "tap_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "finished", default: false, null: false
    t.bigint "player_id", null: false
    t.bigint "round_run_id", null: false
    t.integer "taps", default: 0, null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_tap_runs_on_player_id"
    t.index ["round_run_id", "team_id"], name: "index_tap_runs_on_round_run_id_and_team_id", unique: true
    t.index ["round_run_id"], name: "index_tap_runs_on_round_run_id"
    t.index ["team_id"], name: "index_tap_runs_on_team_id"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_team_memberships_on_player_id", unique: true
    t.index ["team_id", "player_id"], name: "index_team_memberships_on_team_id_and_player_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "cached_score", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "emblem", null: false
    t.bigint "game_session_id", null: false
    t.string "name", null: false
    t.boolean "next_correct_doubled", default: false, null: false
    t.string "pending_rank_up"
    t.string "rank_key", default: "novicio", null: false
    t.string "season_rank_up"
    t.boolean "solo", default: false, null: false
    t.integer "streak", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_team_id"
    t.integer "xp", default: 0, null: false
    t.index ["game_session_id", "name"], name: "index_teams_on_game_session_id_and_name", unique: true
    t.index ["game_session_id"], name: "index_teams_on_game_session_id"
    t.index ["ward_team_id"], name: "index_teams_on_ward_team_id"
  end

  create_table "ward_teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emblem", null: false
    t.string "name", null: false
    t.string "season_rank_key", default: "novicio", null: false
    t.integer "season_xp", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id", null: false
    t.index ["ward_id", "name"], name: "index_ward_teams_on_ward_id_and_name", unique: true
    t.index ["ward_id"], name: "index_ward_teams_on_ward_id"
  end

  create_table "wards", force: :cascade do |t|
    t.string "chapel_address"
    t.string "chapel_name"
    t.string "city"
    t.string "code", null: false
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "emblem", default: "paloma", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.boolean "listed", default: false, null: false
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name", null: false
    t.string "postal_code"
    t.string "presenter_token_digest", null: false
    t.string "region"
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_wards_on_city"
    t.index ["code"], name: "index_wards_on_code", unique: true
    t.index ["country_code"], name: "index_wards_on_country_code"
    t.index ["listed"], name: "index_wards_on_listed", where: "(listed = true)"
  end

  add_foreign_key "answers", "players"
  add_foreign_key "answers", "round_runs"
  add_foreign_key "answers", "teams"
  add_foreign_key "ballots", "players"
  add_foreign_key "ballots", "round_runs"
  add_foreign_key "ballots", "teams"
  add_foreign_key "ballots", "teams", column: "choice_team_id"
  add_foreign_key "buzzes", "players"
  add_foreign_key "buzzes", "round_runs"
  add_foreign_key "buzzes", "teams"
  add_foreign_key "cheers", "players"
  add_foreign_key "cheers", "players", column: "to_player_id"
  add_foreign_key "cheers", "round_runs"
  add_foreign_key "game_sessions", "wards"
  add_foreign_key "missionaries", "game_sessions"
  add_foreign_key "people", "ward_teams", column: "last_ward_team_id"
  add_foreign_key "people", "wards"
  add_foreign_key "person_devices", "people"
  add_foreign_key "players", "game_sessions"
  add_foreign_key "players", "people"
  add_foreign_key "pose_holds", "players"
  add_foreign_key "pose_holds", "round_runs"
  add_foreign_key "pose_holds", "teams"
  add_foreign_key "presenter_blocks", "game_sessions"
  add_foreign_key "presenter_claims", "game_sessions"
  add_foreign_key "quiz_answers", "quiz_runs"
  add_foreign_key "quiz_runs", "people"
  add_foreign_key "reward_grants", "teams"
  add_foreign_key "round_runs", "game_sessions"
  add_foreign_key "score_events", "game_sessions"
  add_foreign_key "score_events", "round_runs"
  add_foreign_key "score_events", "teams"
  add_foreign_key "tap_runs", "players"
  add_foreign_key "tap_runs", "round_runs"
  add_foreign_key "tap_runs", "teams"
  add_foreign_key "team_memberships", "players"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "teams", "game_sessions"
  add_foreign_key "teams", "ward_teams"
  add_foreign_key "ward_teams", "wards"
end
