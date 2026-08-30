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

ActiveRecord::Schema[8.1].define(version: 2026_08_30_141000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

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

  create_table "audience_reactions", force: :cascade do |t|
    t.string "audience_digest", null: false
    t.datetime "created_at", null: false
    t.string "mark", null: false
    t.bigint "round_run_id", null: false
    t.datetime "updated_at", null: false
    t.index ["round_run_id", "audience_digest", "created_at"], name: "index_audience_reactions_on_round_audience_time"
    t.index ["round_run_id"], name: "index_audience_reactions_on_round_run_id"
  end

  create_table "audience_responses", force: :cascade do |t|
    t.datetime "answered_at", null: false
    t.string "audience_digest", null: false
    t.string "choice", null: false
    t.datetime "created_at", null: false
    t.bigint "round_run_id", null: false
    t.datetime "updated_at", null: false
    t.index ["round_run_id", "audience_digest"], name: "index_audience_responses_on_round_run_id_and_audience_digest", unique: true
    t.index ["round_run_id"], name: "index_audience_responses_on_round_run_id"
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

  create_table "duel_invitations", force: :cascade do |t|
    t.bigint "acquisition_parent_invitation_id"
    t.bigint "challenger_person_id", null: false
    t.bigint "challenger_run_id"
    t.integer "challenger_score"
    t.string "channel"
    t.datetime "claimed_at"
    t.bigint "claimed_by_person_id"
    t.datetime "created_at", null: false
    t.datetime "declined_at"
    t.datetime "delivered_at"
    t.datetime "expires_at", null: false
    t.datetime "human_opened_at"
    t.string "legacy_token_digest"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "recipient_person_id"
    t.bigint "rematch_of_duel_id"
    t.datetime "revoked_at"
    t.datetime "seen_at"
    t.datetime "share_handoff_at"
    t.string "source"
    t.string "status", default: "open", null: false
    t.bigint "street_duel_id"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["challenger_person_id", "status", "updated_at"], name: "index_duel_invitations_on_challenger_outbox"
    t.index ["challenger_person_id"], name: "index_duel_invitations_on_challenger_person_id"
    t.index ["challenger_run_id"], name: "index_duel_invitations_on_challenger_run_id"
    t.index ["claimed_by_person_id"], name: "index_duel_invitations_on_claimed_by_person_id"
    t.index ["legacy_token_digest"], name: "index_duel_invitations_on_legacy_token_digest", unique: true, where: "(legacy_token_digest IS NOT NULL)"
    t.index ["recipient_person_id", "status", "updated_at"], name: "index_duel_invitations_on_recipient_inbox"
    t.index ["recipient_person_id"], name: "index_duel_invitations_on_recipient_person_id"
    t.index ["rematch_of_duel_id"], name: "index_duel_invitations_on_rematch_of_duel_id"
    t.index ["street_duel_id"], name: "index_duel_invitations_on_street_duel_id"
    t.index ["token_digest"], name: "index_duel_invitations_on_token_digest", unique: true
    t.check_constraint "recipient_person_id IS NULL OR recipient_person_id <> challenger_person_id", name: "duel_invitations_distinct_people_check"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'claimed'::character varying, 'declined'::character varying, 'expired'::character varying, 'revoked'::character varying]::text[])", name: "duel_invitations_status_check"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.integer "broadcast_delay_ms", default: 0, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "poster_path"
    t.string "presenter_device_digest"
    t.string "presenter_locale", default: "es", null: false
    t.string "presenter_token_digest", null: false
    t.string "public_token", null: false
    t.datetime "season_applied_at"
    t.datetime "starts_at", null: false
    t.string "status", default: "lobby", null: false
    t.string "theme_id", null: false
    t.string "theme_title", null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id", null: false
    t.index ["code"], name: "index_game_sessions_active_code", unique: true, where: "((status)::text <> 'finished'::text)"
    t.index ["code"], name: "index_game_sessions_on_code"
    t.index ["public_token"], name: "index_game_sessions_on_public_token", unique: true
    t.index ["starts_at"], name: "index_game_sessions_on_starts_at"
    t.index ["ward_id", "status", "starts_at", "id"], name: "index_game_sessions_on_ward_schedule"
    t.index ["ward_id"], name: "index_game_sessions_on_ward_id"
  end

  create_table "identity_transfers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "encrypted_payload", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_identity_transfers_on_expires_at"
    t.index ["token_digest"], name: "index_identity_transfers_on_token_digest", unique: true
  end

  create_table "missionaries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_session_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id"], name: "index_missionaries_on_game_session_id"
  end

  create_table "notification_deliveries", force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.string "dedupe_key", null: false
    t.string "destination", null: false
    t.string "error_code"
    t.string "kind", null: false
    t.datetime "opened_at"
    t.bigint "person_id", null: false
    t.datetime "received_at"
    t.datetime "scheduled_for"
    t.datetime "sent_at"
    t.string "status", default: "queued", null: false
    t.bigint "subject_id"
    t.string "subject_type"
    t.datetime "updated_at", null: false
    t.bigint "web_push_subscription_id"
    t.index ["dedupe_key"], name: "index_notification_deliveries_on_dedupe_key", unique: true
    t.index ["person_id"], name: "index_notification_deliveries_on_person_id"
    t.index ["status", "scheduled_for"], name: "index_notification_deliveries_on_status_and_scheduled_for"
    t.index ["subject_type", "subject_id"], name: "index_notification_deliveries_on_subject"
    t.index ["web_push_subscription_id"], name: "index_notification_deliveries_on_web_push_subscription_id"
  end

  create_table "notification_editorial_proposals", force: :cascade do |t|
    t.string "approval_content_digest"
    t.datetime "approval_expires_at"
    t.string "approval_token_digest"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.string "editorial_key", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "proposal_type", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["editorial_key"], name: "index_notification_editorial_proposals_on_editorial_key", unique: true
    t.index ["proposal_type", "status"], name: "idx_on_proposal_type_status_43a8fcffb7"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.boolean "challenges_enabled", default: false, null: false
    t.datetime "challenges_enabled_at"
    t.datetime "created_at", null: false
    t.boolean "nights_enabled", default: false, null: false
    t.datetime "nights_enabled_at"
    t.bigint "person_id", null: false
    t.time "quiet_hours_end", default: "2000-01-01 08:00:00", null: false
    t.time "quiet_hours_start", default: "2000-01-01 21:00:00", null: false
    t.datetime "updated_at", null: false
    t.string "verse_frequency", default: "three_weekly", null: false
    t.time "verse_local_time", default: "2000-01-01 08:00:00", null: false
    t.boolean "verses_enabled", default: false, null: false
    t.datetime "verses_enabled_at"
    t.index ["person_id"], name: "index_notification_preferences_on_person_id", unique: true
  end

  create_table "notification_prompt_states", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.datetime "last_offered_at"
    t.string "last_result"
    t.string "offer_context"
    t.bigint "person_device_id", null: false
    t.datetime "snoozed_until"
    t.datetime "updated_at", null: false
    t.index ["person_device_id", "category"], name: "index_notification_prompt_states_on_device_category", unique: true
    t.index ["person_device_id"], name: "index_notification_prompt_states_on_person_device_id"
    t.index ["snoozed_until"], name: "index_notification_prompt_states_on_snoozed_until"
  end

  create_table "people", force: :cascade do |t|
    t.string "avatar_key", null: false
    t.datetime "created_at", null: false
    t.string "family_name"
    t.string "family_name_key", default: "", null: false
    t.integer "favorite_year"
    t.string "given_name", null: false
    t.string "given_name_key", null: false
    t.bigint "last_ward_team_id"
    t.string "locale", default: "es", null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id"
    t.index ["last_ward_team_id"], name: "index_people_on_last_ward_team_id"
    t.index ["ward_id", "given_name_key", "created_at"], name: "index_people_on_recorded_profile"
    t.index ["ward_id"], name: "index_people_on_ward_id"
  end

  create_table "person_devices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_token", null: false
    t.datetime "last_seen_at"
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["device_token", "person_id"], name: "index_person_devices_on_device_token_and_person_id", unique: true
    t.index ["device_token"], name: "index_person_devices_on_device_token"
    t.index ["last_seen_at", "person_id"], name: "index_person_devices_on_live_presence"
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
    t.integer "base_points"
    t.integer "bonus_lost"
    t.string "choice_key"
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.integer "duration_ms"
    t.string "pack_id", null: false
    t.integer "points_awarded"
    t.string "question_id", null: false
    t.bigint "quiz_run_id", null: false
    t.integer "streak_after"
    t.integer "streak_before"
    t.integer "streak_bonus"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_quiz_answers_on_created_at"
    t.index ["device_digest", "pack_id", "question_id"], name: "idx_on_device_digest_pack_id_question_id_d4c3f03d57"
    t.index ["pack_id", "question_id", "device_digest", "id"], name: "index_quiz_answers_on_tally_lookup"
    t.index ["quiz_run_id", "question_id"], name: "index_quiz_answers_on_quiz_run_id_and_question_id", unique: true
    t.index ["quiz_run_id"], name: "index_quiz_answers_on_quiz_run_id"
  end

  create_table "quiz_runs", force: :cascade do |t|
    t.datetime "asked_at"
    t.integer "base_score", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.datetime "ends_at"
    t.integer "fire_bonus", default: 0, null: false
    t.integer "fire_count", default: 0, null: false
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
    t.index ["person_id", "pack_id", "score"], name: "index_quiz_runs_on_finished_scores", order: { score: :desc }, where: "((status)::text = 'finished'::text)"
    t.index ["person_id"], name: "index_quiz_runs_on_person_id"
  end

  create_table "reading_progresses", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "person_id", null: false
    t.string "reference", null: false
    t.string "status", default: "opened", null: false
    t.bigint "study_unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "study_unit_id", "reference"], name: "index_reading_progress_on_person_unit_reference", unique: true
    t.index ["person_id"], name: "index_reading_progresses_on_person_id"
    t.index ["study_unit_id"], name: "index_reading_progresses_on_study_unit_id"
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

  create_table "scripture_chapter_guides", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "historical_context"
    t.jsonb "key_terms", default: [], null: false
    t.text "literary_structure"
    t.string "locale", null: false
    t.datetime "published_at"
    t.string "reference", null: false
    t.string "reviewed_by"
    t.integer "revision", default: 1, null: false
    t.jsonb "source_citations", default: [], null: false
    t.string "status", default: "draft", null: false
    t.text "summary", null: false
    t.string "theme_key"
    t.datetime "updated_at", null: false
    t.string "welcome_title", null: false
    t.index ["reference", "locale", "revision"], name: "index_scripture_guides_on_reference_locale_revision", unique: true
    t.index ["reference", "locale"], name: "index_scripture_guides_one_published", unique: true, where: "((status)::text = 'published'::text)"
    t.check_constraint "historical_context IS NULL OR char_length(historical_context) <= 1200", name: "scripture_guides_historical_context_length"
    t.check_constraint "literary_structure IS NULL OR char_length(literary_structure) <= 1200", name: "scripture_guides_literary_structure_length"
  end

  create_table "scripture_chapter_reads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "locale", null: false
    t.bigint "person_id"
    t.date "read_on", null: false
    t.string "reader_digest", null: false
    t.string "reference", null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id"
    t.index ["person_id"], name: "index_scripture_chapter_reads_on_person_id"
    t.index ["reference", "created_at"], name: "index_scripture_chapter_reads_on_reference_and_created_at"
    t.index ["reference", "reader_digest", "read_on"], name: "index_scripture_reads_on_reference_reader_day", unique: true
    t.index ["ward_id"], name: "index_scripture_chapter_reads_on_ward_id"
  end

  create_table "scripture_chapter_stats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.bigint "reads_count", default: 0, null: false
    t.string "reference", null: false
    t.datetime "updated_at", null: false
    t.index ["reads_count", "reference"], name: "index_scripture_chapter_stats_on_reads_count_and_reference"
    t.index ["reference"], name: "index_scripture_chapter_stats_on_reference", unique: true
  end

  create_table "scripture_circle_moderation_ballot_revisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "new_choice", null: false
    t.string "previous_choice"
    t.bigint "proposal_id", null: false
    t.bigint "scripture_circle_moderation_ballot_id", null: false
    t.bigint "voter_person_id"
    t.bigint "ward_id", null: false
    t.index ["proposal_id"], name: "idx_on_proposal_id_3f9a25018d"
    t.index ["scripture_circle_moderation_ballot_id"], name: "index_scripture_circle_ballot_revisions_on_ballot"
    t.index ["voter_person_id"], name: "idx_on_voter_person_id_45524b4908"
    t.index ["ward_id"], name: "index_scripture_circle_moderation_ballot_revisions_on_ward_id"
  end

  create_table "scripture_circle_moderation_ballots", force: :cascade do |t|
    t.datetime "cast_at", null: false
    t.string "choice", null: false
    t.datetime "created_at", null: false
    t.bigint "scripture_circle_moderation_proposal_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "voter_person_id"
    t.bigint "ward_id", null: false
    t.index ["scripture_circle_moderation_proposal_id", "voter_person_id"], name: "index_scripture_circle_ballots_unique", unique: true
    t.index ["scripture_circle_moderation_proposal_id"], name: "index_scripture_circle_ballots_on_proposal_id"
    t.index ["voter_person_id"], name: "index_scripture_circle_moderation_ballots_on_voter_person_id"
    t.index ["ward_id"], name: "index_scripture_circle_moderation_ballots_on_ward_id"
  end

  create_table "scripture_circle_moderation_events", force: :cascade do |t|
    t.bigint "actor_person_id"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "post_id", null: false
    t.bigint "proposal_id", null: false
    t.bigint "ward_id", null: false
    t.index ["actor_person_id"], name: "index_scripture_circle_moderation_events_on_actor_person_id"
    t.index ["post_id"], name: "index_scripture_circle_moderation_events_on_post_id"
    t.index ["proposal_id", "created_at"], name: "index_scripture_circle_events_timeline"
    t.index ["proposal_id"], name: "index_scripture_circle_moderation_events_on_proposal_id"
    t.index ["ward_id"], name: "index_scripture_circle_moderation_events_on_ward_id"
  end

  create_table "scripture_circle_moderation_proposals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.integer "no_count", default: 0, null: false
    t.string "policy_version", null: false
    t.bigint "post_revision_id", null: false
    t.bigint "proposer_person_id"
    t.string "reason_details"
    t.string "reason_key", null: false
    t.datetime "resolved_at"
    t.string "result_digest"
    t.bigint "scripture_circle_post_id", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.integer "valid_ballot_count", default: 0, null: false
    t.bigint "ward_id", null: false
    t.integer "yes_count", default: 0, null: false
    t.index ["post_revision_id"], name: "idx_on_post_revision_id_2bca440cfb"
    t.index ["proposer_person_id"], name: "idx_on_proposer_person_id_5120543e4c"
    t.index ["scripture_circle_post_id"], name: "index_scripture_circle_one_open_proposal", unique: true, where: "((status)::text = 'open'::text)"
    t.index ["scripture_circle_post_id"], name: "index_scripture_circle_proposals_on_post_id"
    t.index ["status", "ends_at"], name: "index_scripture_circle_due_proposals"
    t.index ["ward_id"], name: "index_scripture_circle_moderation_proposals_on_ward_id"
    t.check_constraint "ends_at >= (starts_at + 'P2D'::interval)", name: "scripture_circle_proposals_minimum_duration"
    t.check_constraint "reason_details IS NULL OR char_length(reason_details::text) <= 240", name: "scripture_circle_proposals_reason_length"
    t.check_constraint "yes_count >= 0 AND no_count >= 0 AND valid_ballot_count >= 0", name: "scripture_circle_proposals_nonnegative_counts"
  end

  create_table "scripture_circle_post_revisions", force: :cascade do |t|
    t.boolean "anonymous", default: true, null: false
    t.text "body", null: false
    t.string "change_kind", null: false
    t.string "content_digest", null: false
    t.datetime "created_at", null: false
    t.bigint "editor_person_id"
    t.integer "end_verse"
    t.integer "revision_number", null: false
    t.bigint "scripture_circle_post_id", null: false
    t.integer "start_verse"
    t.bigint "ward_id", null: false
    t.index ["editor_person_id"], name: "index_scripture_circle_post_revisions_on_editor_person_id"
    t.index ["scripture_circle_post_id", "revision_number"], name: "index_scripture_circle_revisions_unique", unique: true
    t.index ["scripture_circle_post_id"], name: "index_scripture_circle_revisions_on_post_id"
    t.index ["ward_id"], name: "index_scripture_circle_post_revisions_on_ward_id"
    t.check_constraint "char_length(body) >= 1 AND char_length(body) <= 500", name: "scripture_circle_revisions_body_length"
  end

  create_table "scripture_circle_posts", force: :cascade do |t|
    t.boolean "anonymous", default: true, null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "edited_at"
    t.integer "end_verse"
    t.string "kind", null: false
    t.string "locale", null: false
    t.bigint "parent_id"
    t.bigint "person_id"
    t.bigint "scripture_circle_thread_id", null: false
    t.text "selected_text"
    t.integer "start_verse"
    t.string "status", default: "visible", null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id", null: false
    t.index ["parent_id"], name: "index_scripture_circle_posts_on_parent_id"
    t.index ["person_id", "created_at"], name: "index_scripture_circle_posts_for_profile", order: { created_at: :desc }
    t.index ["person_id"], name: "index_scripture_circle_posts_on_person_id"
    t.index ["scripture_circle_thread_id"], name: "index_scripture_circle_posts_on_thread_id"
    t.index ["ward_id", "status", "created_at"], name: "index_scripture_circle_posts_for_ward"
    t.index ["ward_id"], name: "index_scripture_circle_posts_on_ward_id"
    t.check_constraint "char_length(body) >= 1 AND char_length(body) <= 500", name: "scripture_circle_posts_body_length"
    t.check_constraint "selected_text IS NULL OR char_length(selected_text) <= 1000", name: "scripture_circle_posts_selected_text_length"
  end

  create_table "scripture_circle_threads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "reference", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "ward_id", null: false
    t.index ["ward_id", "reference"], name: "index_scripture_circle_threads_on_ward_id_and_reference", unique: true
    t.index ["ward_id"], name: "index_scripture_circle_threads_on_ward_id"
  end

  create_table "scripture_highlights", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "end_offset", null: false
    t.integer "end_verse", null: false
    t.string "locale", null: false
    t.bigint "person_id", null: false
    t.string "reference", null: false
    t.text "selected_text"
    t.integer "start_offset", null: false
    t.integer "start_verse", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "reference", "locale", "start_verse", "end_verse", "start_offset", "end_offset"], name: "index_scripture_highlights_on_person_and_range", unique: true
    t.index ["person_id"], name: "index_scripture_highlights_on_person_id"
    t.index ["reference", "locale"], name: "index_scripture_highlights_on_reference_and_locale"
    t.check_constraint "start_verse > 0 AND end_verse >= start_verse AND start_offset >= 0 AND end_offset >= 0", name: "scripture_highlights_valid_range"
  end

  create_table "scripture_mark_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "scripture_mark_id", null: false
    t.integer "target_end_offset"
    t.integer "target_end_verse"
    t.string "target_locale", null: false
    t.string "target_reference", null: false
    t.integer "target_start_offset"
    t.integer "target_start_verse"
    t.text "target_text"
    t.datetime "updated_at", null: false
    t.index ["scripture_mark_id", "target_reference", "target_locale"], name: "index_scripture_mark_links_on_target"
    t.index ["scripture_mark_id"], name: "index_scripture_mark_links_on_scripture_mark_id"
  end

  create_table "scripture_mark_taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "scripture_mark_id", null: false
    t.bigint "scripture_tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["scripture_mark_id", "scripture_tag_id"], name: "index_scripture_mark_taggings_unique", unique: true
    t.index ["scripture_mark_id"], name: "index_scripture_mark_taggings_on_scripture_mark_id"
    t.index ["scripture_tag_id"], name: "index_scripture_mark_taggings_on_scripture_tag_id"
  end

  create_table "scripture_marks", force: :cascade do |t|
    t.string "anchor_scope", default: "passage", null: false
    t.datetime "bookmarked_at"
    t.string "color_key"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "end_offset"
    t.integer "end_verse"
    t.string "intent_key"
    t.string "locale", null: false
    t.text "note_body"
    t.bigint "person_id", null: false
    t.string "reference", null: false
    t.text "selected_text"
    t.string "source_digest"
    t.integer "start_offset"
    t.integer "start_verse"
    t.datetime "updated_at", null: false
    t.string "visual_style", default: "none", null: false
    t.index ["person_id", "reference", "locale", "discarded_at"], name: "index_scripture_marks_for_reader"
    t.index ["person_id", "reference", "locale", "start_verse", "end_verse", "start_offset", "end_offset"], name: "index_scripture_marks_on_person_and_range"
    t.index ["person_id"], name: "index_scripture_marks_on_person_id"
    t.check_constraint "anchor_scope::text = 'chapter'::text AND start_verse IS NULL AND start_offset IS NULL AND end_verse IS NULL AND end_offset IS NULL OR anchor_scope::text = 'passage'::text AND start_verse > 0 AND end_verse >= start_verse AND start_offset >= 0 AND end_offset >= 0", name: "scripture_marks_valid_anchor"
    t.check_constraint "note_body IS NULL OR char_length(note_body) <= 5000", name: "scripture_marks_note_length"
    t.check_constraint "selected_text IS NULL OR char_length(selected_text) <= 10000", name: "scripture_marks_selected_text_length"
  end

  create_table "scripture_notebook_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "scripture_mark_id", null: false
    t.bigint "scripture_notebook_id", null: false
    t.datetime "updated_at", null: false
    t.index ["scripture_mark_id"], name: "index_scripture_notebook_entries_on_scripture_mark_id"
    t.index ["scripture_notebook_id", "scripture_mark_id"], name: "index_scripture_notebook_entries_unique", unique: true
    t.index ["scripture_notebook_id"], name: "index_scripture_notebook_entries_on_scripture_notebook_id"
  end

  create_table "scripture_notebooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "person_id", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "position"], name: "index_scripture_notebooks_on_person_id_and_position"
    t.index ["person_id"], name: "index_scripture_notebooks_on_person_id"
  end

  create_table "scripture_reader_preferences", force: :cascade do |t|
    t.string "background_key", default: "paper", null: false
    t.datetime "created_at", null: false
    t.string "font_family_key", default: "editorial", null: false
    t.integer "font_scale", default: 100, null: false
    t.boolean "illustrations_enabled", default: true, null: false
    t.string "line_height_key", default: "comfortable", null: false
    t.string "measure_key", default: "comfortable", null: false
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_scripture_reader_preferences_on_person_id", unique: true
    t.check_constraint "font_scale = ANY (ARRAY[90, 100, 115, 130, 145])", name: "scripture_reader_preferences_font_scale"
  end

  create_table "scripture_reading_progresses", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "first_opened_at", null: false
    t.integer "last_offset"
    t.datetime "last_opened_at", null: false
    t.integer "last_verse", default: 1, null: false
    t.string "locale", null: false
    t.bigint "person_id", null: false
    t.decimal "progress_ratio", precision: 6, scale: 5, default: "0.0", null: false
    t.string "reference", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "reference", "locale"], name: "index_scripture_progresses_on_person_reference_locale", unique: true
    t.index ["person_id"], name: "index_scripture_reading_progresses_on_person_id"
    t.check_constraint "last_verse > 0 AND progress_ratio >= 0::numeric AND progress_ratio <= 1::numeric", name: "scripture_reading_progresses_valid_position"
  end

  create_table "scripture_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "normalized_name"], name: "index_scripture_tags_on_person_id_and_normalized_name", unique: true
    t.index ["person_id"], name: "index_scripture_tags_on_person_id"
  end

  create_table "scripture_video_links", force: :cascade do |t|
    t.integer "anchor_verse"
    t.string "channel_id", null: false
    t.datetime "created_at", null: false
    t.text "editorial_reason", null: false
    t.string "locale", null: false
    t.integer "position", default: 0, null: false
    t.datetime "published_at"
    t.string "reference", null: false
    t.string "reviewed_by"
    t.string "source_url"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.string "youtube_video_id", null: false
    t.index ["reference", "locale", "status", "position"], name: "index_scripture_video_links_for_reader"
    t.index ["reference", "locale", "youtube_video_id"], name: "index_scripture_video_links_unique", unique: true
    t.check_constraint "status::text <> 'published'::text OR verified_at IS NOT NULL AND published_at IS NOT NULL AND reviewed_by IS NOT NULL AND source_url IS NOT NULL", name: "scripture_video_links_published_metadata"
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

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.integer "completed_jobs", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "enqueued_at"
    t.datetime "failed_at"
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "finished_at"
    t.text "metadata"
    t.text "on_failure"
    t.text "on_finish"
    t.text "on_success"
    t.integer "total_jobs", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.bigint "batch_id"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "street_duels", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "challenger_person_id", null: false
    t.datetime "challenger_result_seen_at"
    t.bigint "challenger_run_id"
    t.integer "challenger_score"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "opponent_person_id", null: false
    t.datetime "opponent_result_seen_at"
    t.bigint "opponent_run_id"
    t.integer "opponent_score"
    t.bigint "origin_invitation_id", null: false
    t.bigint "pair_high_person_id", null: false
    t.bigint "pair_low_person_id", null: false
    t.bigint "rematch_of_id"
    t.datetime "resolved_at"
    t.datetime "resolved_notified_at"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["challenger_person_id", "status", "updated_at"], name: "index_street_duels_on_challenger_inbox", order: { updated_at: :desc }
    t.index ["challenger_person_id"], name: "index_street_duels_on_challenger_person_id"
    t.index ["challenger_run_id"], name: "index_street_duels_on_challenger_run_id"
    t.index ["opponent_person_id", "status", "updated_at"], name: "index_street_duels_on_opponent_inbox", order: { updated_at: :desc }
    t.index ["opponent_person_id"], name: "index_street_duels_on_opponent_person_id"
    t.index ["opponent_run_id"], name: "index_street_duels_on_opponent_run_id"
    t.index ["origin_invitation_id"], name: "index_street_duels_on_origin_invitation_id"
    t.index ["pair_low_person_id", "pair_high_person_id"], name: "index_street_duels_on_unique_active_pair", unique: true, where: "((status)::text = ANY ((ARRAY['active'::character varying, 'one_scored'::character varying])::text[]))"
    t.index ["rematch_of_id"], name: "index_street_duels_on_rematch_of_id"
    t.index ["status"], name: "index_street_duels_on_status"
    t.check_constraint "challenger_person_id <> opponent_person_id", name: "street_duels_distinct_people_check"
    t.check_constraint "pair_low_person_id < pair_high_person_id", name: "street_duels_ordered_pair_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'one_scored'::character varying, 'resolved'::character varying, 'expired'::character varying, 'archived'::character varying]::text[])", name: "street_duels_status_check"
  end

  create_table "study_answers", force: :cascade do |t|
    t.string "choice_key", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.string "question_key", null: false
    t.bigint "study_run_id", null: false
    t.datetime "updated_at", null: false
    t.index ["study_run_id", "question_key"], name: "index_study_answers_on_study_run_id_and_question_key", unique: true
    t.index ["study_run_id"], name: "index_study_answers_on_study_run_id"
  end

  create_table "study_programs", force: :cascade do |t|
    t.string "canon", null: false
    t.datetime "created_at", null: false
    t.datetime "imported_at"
    t.string "locale", default: "fr", null: false
    t.string "slug", null: false
    t.string "source_digest"
    t.text "source_url", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["slug"], name: "index_study_programs_on_slug", unique: true
    t.index ["year", "locale"], name: "index_study_programs_on_year_and_locale", unique: true
  end

  create_table "study_quiz_versions", force: :cascade do |t|
    t.jsonb "content", default: {}, null: false
    t.string "content_digest", null: false
    t.datetime "created_at", null: false
    t.string "editorial_locale", default: "fr", null: false
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.bigint "study_unit_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["study_unit_id", "status"], name: "index_study_quiz_versions_on_study_unit_id_and_status"
    t.index ["study_unit_id", "version"], name: "index_study_quiz_versions_on_study_unit_id_and_version", unique: true
    t.index ["study_unit_id"], name: "index_study_quiz_versions_on_study_unit_id"
  end

  create_table "study_runs", force: :cascade do |t|
    t.datetime "asked_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.datetime "opened_at", null: false
    t.bigint "person_id"
    t.integer "position", default: 1, null: false
    t.integer "score", default: 0, null: false
    t.string "status", default: "open", null: false
    t.bigint "study_quiz_version_id", null: false
    t.datetime "updated_at", null: false
    t.index ["device_digest", "status"], name: "index_study_runs_on_device_digest_and_status"
    t.index ["person_id", "study_quiz_version_id", "status"], name: "index_study_runs_on_person_quiz_status"
    t.index ["person_id"], name: "index_study_runs_on_person_id"
    t.index ["study_quiz_version_id"], name: "index_study_runs_on_study_quiz_version_id"
  end

  create_table "study_units", force: :cascade do |t|
    t.jsonb "copy", default: {}, null: false
    t.datetime "created_at", null: false
    t.date "ends_on"
    t.string "kind", null: false
    t.integer "position", null: false
    t.jsonb "scripture_refs", default: [], null: false
    t.string "slug", null: false
    t.text "source_url", null: false
    t.date "starts_on"
    t.string "status", default: "imported", null: false
    t.bigint "study_program_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["starts_on", "ends_on"], name: "index_study_units_on_starts_on_and_ends_on"
    t.index ["study_program_id", "kind", "position"], name: "index_study_units_on_program_kind_position", unique: true
    t.index ["study_program_id", "slug"], name: "index_study_units_on_study_program_id_and_slug", unique: true
    t.index ["study_program_id"], name: "index_study_units_on_study_program_id"
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

  create_table "viral_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_digest", null: false
    t.bigint "duel_invitation_id"
    t.string "event_key"
    t.string "name", null: false
    t.bigint "person_id"
    t.jsonb "properties", default: {}, null: false
    t.string "source"
    t.bigint "street_duel_id"
    t.datetime "updated_at", null: false
    t.index ["duel_invitation_id"], name: "index_viral_events_on_duel_invitation_id"
    t.index ["event_key"], name: "index_viral_events_on_event_key", unique: true, where: "(event_key IS NOT NULL)"
    t.index ["name", "created_at"], name: "index_viral_events_on_name_and_created_at"
    t.index ["person_id"], name: "index_viral_events_on_person_id"
    t.index ["street_duel_id", "name", "created_at"], name: "index_viral_events_on_duel_funnel"
    t.index ["street_duel_id"], name: "index_viral_events_on_street_duel_id"
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
    t.string "church_unit_id"
    t.string "city"
    t.string "code", null: false
    t.string "country_code"
    t.string "country_name"
    t.datetime "created_at", null: false
    t.string "emblem", default: "paloma", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.boolean "listed", default: false, null: false
    t.jsonb "locator_payload"
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name", null: false
    t.string "postal_code"
    t.string "presenter_token_digest", null: false
    t.string "region"
    t.string "scripture_circle_mode", default: "disabled", null: false
    t.string "stake_name"
    t.string "stake_unit_id"
    t.string "unit_kind"
    t.datetime "updated_at", null: false
    t.index ["church_unit_id"], name: "index_wards_on_church_unit_id", unique: true, where: "(church_unit_id IS NOT NULL)"
    t.index ["city"], name: "index_wards_on_city"
    t.index ["city"], name: "index_wards_on_city_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["code"], name: "index_wards_on_code", unique: true
    t.index ["country_code"], name: "index_wards_on_country_code"
    t.index ["listed", "country_code", "stake_name"], name: "index_wards_on_listed_country_stake"
    t.index ["listed"], name: "index_wards_on_listed", where: "(listed = true)"
    t.index ["name"], name: "index_wards_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["stake_name"], name: "index_wards_on_stake_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["stake_unit_id"], name: "index_wards_on_stake_unit_id"
    t.check_constraint "scripture_circle_mode::text = ANY (ARRAY['disabled'::character varying, 'read_only'::character varying, 'active'::character varying]::text[])", name: "wards_scripture_circle_mode"
  end

  create_table "web_push_subscriptions", force: :cascade do |t|
    t.text "auth_ciphertext", null: false
    t.datetime "created_at", null: false
    t.string "device_token_digest", null: false
    t.text "endpoint_ciphertext", null: false
    t.string "endpoint_digest", null: false
    t.integer "failure_count", default: 0, null: false
    t.datetime "last_failure_at"
    t.datetime "last_success_at"
    t.string "locale", default: "es", null: false
    t.text "p256dh_ciphertext", null: false
    t.bigint "person_id", null: false
    t.datetime "revoked_at"
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent_family"
    t.index ["endpoint_digest"], name: "index_web_push_subscriptions_on_endpoint_digest", unique: true
    t.index ["person_id", "device_token_digest"], name: "index_push_subscriptions_on_person_device"
    t.index ["person_id"], name: "index_web_push_subscriptions_on_person_id"
    t.index ["revoked_at"], name: "index_web_push_subscriptions_on_revoked_at"
  end

  add_foreign_key "answers", "players"
  add_foreign_key "answers", "round_runs"
  add_foreign_key "answers", "teams"
  add_foreign_key "audience_reactions", "round_runs"
  add_foreign_key "audience_responses", "round_runs"
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
  add_foreign_key "duel_invitations", "duel_invitations", column: "acquisition_parent_invitation_id"
  add_foreign_key "duel_invitations", "people", column: "challenger_person_id"
  add_foreign_key "duel_invitations", "people", column: "claimed_by_person_id"
  add_foreign_key "duel_invitations", "people", column: "recipient_person_id"
  add_foreign_key "duel_invitations", "quiz_runs", column: "challenger_run_id", on_delete: :nullify
  add_foreign_key "duel_invitations", "street_duels"
  add_foreign_key "duel_invitations", "street_duels", column: "rematch_of_duel_id"
  add_foreign_key "game_sessions", "wards"
  add_foreign_key "missionaries", "game_sessions"
  add_foreign_key "notification_deliveries", "people"
  add_foreign_key "notification_deliveries", "web_push_subscriptions"
  add_foreign_key "notification_preferences", "people"
  add_foreign_key "notification_prompt_states", "person_devices"
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
  add_foreign_key "reading_progresses", "people"
  add_foreign_key "reading_progresses", "study_units"
  add_foreign_key "reward_grants", "teams"
  add_foreign_key "round_runs", "game_sessions"
  add_foreign_key "score_events", "game_sessions"
  add_foreign_key "score_events", "round_runs"
  add_foreign_key "score_events", "teams"
  add_foreign_key "scripture_chapter_reads", "people", on_delete: :nullify
  add_foreign_key "scripture_chapter_reads", "wards", on_delete: :nullify
  add_foreign_key "scripture_circle_moderation_ballot_revisions", "people", column: "voter_person_id", on_delete: :nullify
  add_foreign_key "scripture_circle_moderation_ballot_revisions", "scripture_circle_moderation_ballots", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_ballot_revisions", "scripture_circle_moderation_proposals", column: "proposal_id", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_ballot_revisions", "wards", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_ballots", "people", column: "voter_person_id", on_delete: :nullify
  add_foreign_key "scripture_circle_moderation_ballots", "scripture_circle_moderation_proposals", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_ballots", "wards", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_events", "people", column: "actor_person_id", on_delete: :nullify
  add_foreign_key "scripture_circle_moderation_events", "scripture_circle_moderation_proposals", column: "proposal_id", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_events", "scripture_circle_posts", column: "post_id", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_events", "wards", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_proposals", "people", column: "proposer_person_id", on_delete: :nullify
  add_foreign_key "scripture_circle_moderation_proposals", "scripture_circle_post_revisions", column: "post_revision_id", on_delete: :restrict
  add_foreign_key "scripture_circle_moderation_proposals", "scripture_circle_posts", on_delete: :cascade
  add_foreign_key "scripture_circle_moderation_proposals", "wards", on_delete: :cascade
  add_foreign_key "scripture_circle_post_revisions", "people", column: "editor_person_id", on_delete: :nullify
  add_foreign_key "scripture_circle_post_revisions", "scripture_circle_posts", on_delete: :cascade
  add_foreign_key "scripture_circle_post_revisions", "wards", on_delete: :cascade
  add_foreign_key "scripture_circle_posts", "people", on_delete: :nullify
  add_foreign_key "scripture_circle_posts", "scripture_circle_posts", column: "parent_id", on_delete: :nullify
  add_foreign_key "scripture_circle_posts", "scripture_circle_threads", on_delete: :cascade
  add_foreign_key "scripture_circle_posts", "wards", on_delete: :cascade
  add_foreign_key "scripture_circle_threads", "wards", on_delete: :cascade
  add_foreign_key "scripture_highlights", "people", on_delete: :cascade
  add_foreign_key "scripture_mark_links", "scripture_marks", on_delete: :cascade
  add_foreign_key "scripture_mark_taggings", "scripture_marks", on_delete: :cascade
  add_foreign_key "scripture_mark_taggings", "scripture_tags", on_delete: :cascade
  add_foreign_key "scripture_marks", "people", on_delete: :cascade
  add_foreign_key "scripture_notebook_entries", "scripture_marks", on_delete: :cascade
  add_foreign_key "scripture_notebook_entries", "scripture_notebooks", on_delete: :cascade
  add_foreign_key "scripture_notebooks", "people", on_delete: :cascade
  add_foreign_key "scripture_reader_preferences", "people", on_delete: :cascade
  add_foreign_key "scripture_reading_progresses", "people", on_delete: :cascade
  add_foreign_key "scripture_tags", "people", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "street_duels", "duel_invitations", column: "origin_invitation_id"
  add_foreign_key "street_duels", "people", column: "challenger_person_id"
  add_foreign_key "street_duels", "people", column: "opponent_person_id"
  add_foreign_key "street_duels", "quiz_runs", column: "challenger_run_id", on_delete: :nullify
  add_foreign_key "street_duels", "quiz_runs", column: "opponent_run_id", on_delete: :nullify
  add_foreign_key "street_duels", "street_duels", column: "rematch_of_id"
  add_foreign_key "study_answers", "study_runs"
  add_foreign_key "study_quiz_versions", "study_units"
  add_foreign_key "study_runs", "people"
  add_foreign_key "study_runs", "study_quiz_versions"
  add_foreign_key "study_units", "study_programs"
  add_foreign_key "tap_runs", "players"
  add_foreign_key "tap_runs", "round_runs"
  add_foreign_key "tap_runs", "teams"
  add_foreign_key "team_memberships", "players"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "teams", "game_sessions"
  add_foreign_key "teams", "ward_teams"
  add_foreign_key "viral_events", "duel_invitations"
  add_foreign_key "viral_events", "people"
  add_foreign_key "viral_events", "street_duels"
  add_foreign_key "ward_teams", "wards"
  add_foreign_key "web_push_subscriptions", "people"
end
