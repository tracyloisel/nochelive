require "test_helper"

class AdminApiTest < ActionDispatch::IntegrationTest
  TOKEN = "admin-test-token-that-is-at-least-32-characters"

  setup do
    @previous_token = ENV["NOCHE_ADMIN_API_TOKEN"]
    @previous_audit_actor = ENV["NOCHE_ADMIN_API_AUDIT_ACTOR"]
    ENV["NOCHE_ADMIN_API_TOKEN"] = TOKEN
    ENV["NOCHE_ADMIN_API_AUDIT_ACTOR"] = "Noche Live admin test"
  end

  teardown do
    ENV["NOCHE_ADMIN_API_TOKEN"] = @previous_token
    ENV["NOCHE_ADMIN_API_AUDIT_ACTOR"] = @previous_audit_actor
  end

  test "rejects requests without the private bearer token" do
    get admin_api_wards_path

    assert_response :unauthorized
  end

  test "searches wards and inspects their profiles" do
    get admin_api_wards_path, params: { q: "Benidorm" }, headers: auth_headers

    assert_response :success
    assert_equal wards(:demo).code, response.parsed_body.dig("wards", 0, "code")

    get admin_api_ward_path(wards(:demo).code), headers: auth_headers

    assert_response :success
    carmen = response.parsed_body.dig("ward", "people").find { |person| person["name"].start_with?("Carmen") }
    assert carmen["avatar"].present?
    assert carmen.key?("points")
    assert carmen["created_at"].present?
  end

  test "creates a persistent team inside an explicit ward" do
    ward = wards(:blank)

    assert_difference("ward.ward_teams.count", 1) do
      post admin_api_ward_ward_teams_path(ward.code),
           params: { name: "Les Oliviers", emblem: "paloma" },
           headers: auth_headers,
           as: :json
    end

    assert_response :created
    assert_equal "Les Oliviers", response.parsed_body.dig("team", "name")
    assert_equal "paloma", response.parsed_body.dig("team", "emblem")
    assert_equal ward.code, response.parsed_body.dig("team", "ward_code")
  end

  test "rejects an invalid persistent team" do
    post admin_api_ward_ward_teams_path(wards(:blank).code),
         params: { name: "T" * (WardTeam::NAME_MAX + 1), emblem: "paloma" },
         headers: auth_headers,
         as: :json

    assert_response :unprocessable_entity
  end

  test "returns aggregate platform and ward statistics" do
    get admin_api_stats_path, headers: auth_headers

    assert_response :success
    assert_equal Person.count, response.parsed_body.dig("platform", "people")
    assert response.parsed_body.dig("platform", "quiz_answers").is_a?(Integer)
    assert_nil response.parsed_body.dig("platform", "world")

    get stats_admin_api_ward_path(wards(:demo).code), headers: auth_headers

    assert_response :success
    ward_stats = response.parsed_body.fetch("ward")
    assert_equal wards(:demo).people.count, ward_stats.fetch("people_count")
    assert ward_stats.fetch("total_best_points").is_a?(Integer)
    assert ward_stats.fetch("completed_readings").is_a?(Integer)
    assert_nil ward_stats["people"]
  end

  test "lists people seen today worldwide or filtered by country and ward" do
    active = people(:carmen_garcia)
    inactive = people(:pili)
    active.person_devices.create!(device_token: "today-phone", last_seen_at: Time.current)
    inactive.person_devices.update_all(last_seen_at: 2.days.ago)
    inactive.person_devices.create!(device_token: "old-phone", last_seen_at: 2.days.ago)

    get admin_api_people_seen_today_path,
        params: { timezone: "Europe/Madrid" },
        headers: auth_headers

    assert_response :success
    assert_includes response.parsed_body.fetch("people").pluck("id"), active.id
    assert_not_includes response.parsed_body.fetch("people").pluck("id"), inactive.id

    get admin_api_people_seen_today_path,
        params: { country: "ES", ward_code: wards(:demo).code, timezone: "Europe/Madrid" },
        headers: auth_headers

    assert_response :success
    row = response.parsed_body.fetch("people").find { |person| person["id"] == active.id }
    assert_equal wards(:demo).code, row.fetch("ward_code")
    assert_equal "ES", row.fetch("country_code")
    assert row.fetch("last_seen_at").present?
  end

  test "rejects an invalid presence date or timezone" do
    get admin_api_people_seen_today_path,
        params: { date: "not-a-date" },
        headers: auth_headers
    assert_response :unprocessable_entity

    get admin_api_people_seen_today_path,
        params: { timezone: "Moon/Base" },
        headers: auth_headers
    assert_response :unprocessable_entity
  end

  test "previews then performs one exact profile merge" do
    oldest = people(:carmen_garcia)
    newer = people(:carmen_lopez)
    oldest.update_column(:created_at, 2.years.ago)
    newer.update_column(:created_at, 1.year.ago)

    post admin_api_profile_merges_preview_path,
         params: { ward_code: wards(:demo).code, first_id: newer.id, second_id: oldest.id },
         headers: auth_headers,
         as: :json

    assert_response :success
    assert_equal oldest.id, response.parsed_body.dig("preview", "keeper", "id")
    confirmation = response.parsed_body.fetch("confirmation")

    assert_difference("Person.count", -1) do
      post admin_api_profile_merges_path,
           params: { confirmation: },
           headers: auth_headers,
           as: :json
    end
    assert_response :success
    assert Person.exists?(oldest.id)
    assert_not Person.exists?(newer.id)

    post admin_api_profile_merges_path,
         params: { confirmation: },
         headers: auth_headers,
         as: :json
    assert_response :unprocessable_entity
  end

  test "creates and edits a Noche Live inside an explicit ward" do
    ward = wards(:blank)

    assert_difference("ward.game_sessions.count", 1) do
      post admin_api_ward_nights_path(ward.code),
           params: {
             starts_at: 1.day.from_now.change(usec: 0).iso8601,
             quiz_ids: [ "coronas", "moises", "nazareno" ]
           },
           headers: auth_headers,
           as: :json
    end

    assert_response :created
    code = response.parsed_body.dig("night", "code")
    night = ward.game_sessions.find_by!(code:)
    assert_equal [ "coronas", "moises", "nazareno" ], night.quiz_pack_ids
    assert_equal night.starts_at + 1.hour, night.ends_at
    assert_equal "/s/#{code}", response.parsed_body.dig("night", "paths", "canonical")
    assert_equal "/s/#{code}/name", response.parsed_body.dig("night", "paths", "players")
    assert_equal "/s/#{code}/play", response.parsed_body.dig("night", "paths", "play")
    assert_equal 3, response.parsed_body.dig("night", "quizzes").size

    patch admin_api_ward_night_path(ward.code, code),
          params: {
            starts_at: 2.days.from_now.change(usec: 0).iso8601,
            quiz_ids: [ "coronas", "placas" ]
          },
          headers: auth_headers,
          as: :json

    assert_response :success
    assert_equal [ "coronas", "placas" ], night.reload.quiz_pack_ids
    assert_equal night.starts_at + 1.hour, night.ends_at
  end

  test "cannot edit a Noche Live through another ward" do
    patch admin_api_ward_night_path(wards(:blank).code, game_sessions(:david).code),
          params: { quiz_ids: [ "coronas", "placas" ] },
          headers: auth_headers,
          as: :json

    assert_response :not_found
    assert_equal [ "coronas" ], game_sessions(:david).reload.quiz_pack_ids
  end

  test "finishes a Noche Live inside its ward and accepts idempotent retries" do
    ward = wards(:demo)
    night = game_sessions(:david)
    night.update_columns(starts_at: 5.minutes.ago, ends_at: 55.minutes.from_now, status: "playing", closed_at: nil)

    post admin_api_ward_finish_night_path(ward.code, night.code),
         headers: auth_headers,
         as: :json

    assert_response :success
    assert_equal "finished", response.parsed_body.dig("night", "status")
    assert night.reload.finished?
    assert night.closed_at.present?
    first_applied_at = night.closed_at

    post admin_api_ward_finish_night_path(ward.code, night.code),
         headers: auth_headers,
         as: :json

    assert_response :success
    assert_equal first_applied_at, night.reload.closed_at
  end

  test "cannot finish a Noche Live through another ward" do
    night = game_sessions(:david)

    post admin_api_ward_finish_night_path(wards(:blank).code, night.code),
         headers: auth_headers,
         as: :json

    assert_response :not_found
    assert_not night.reload.finished?
  end

  test "rejects invalid Noche Live configuration" do
    post admin_api_ward_nights_path(wards(:blank).code),
         params: { starts_at: "tomorrow evening", quiz_ids: [ "missing" ] },
         headers: auth_headers,
         as: :json

    assert_response :unprocessable_entity

    post admin_api_ward_nights_path(wards(:blank).code),
         params: { starts_at: 1.day.from_now.iso8601, quiz_ids: [] },
         headers: auth_headers,
         as: :json

    assert_response :unprocessable_entity
  end

  test "keeps ward events as explicit drafts with a server-owned audit actor" do
    ward = wards(:demo)

    assert_difference("WardEvent.count", 1) do
      post admin_api_ward_ward_events_path(ward.code),
           params: ward_event_payload(actor: "Usurpatrice depuis le payload"),
           headers: auth_headers,
           as: :json
    end

    assert_response :created
    event_id = response.parsed_body.dig("event", "id")
    assert_equal "draft", response.parsed_body.dig("event", "status")
    assert_equal [ "created" ], response.parsed_body.dig("event", "audit").pluck("action")
    assert_equal [ "Noche Live admin test" ], response.parsed_body.dig("event", "audit").pluck("actor")

    patch admin_api_ward_ward_event_path(ward.code, event_id),
          params: { actor: "Autre identité falsifiée", title: "Collecte alimentaire du samedi" },
          headers: auth_headers,
          as: :json
    assert_response :success
    assert_equal "Collecte alimentaire du samedi", response.parsed_body.dig("event", "title")
    assert_equal %w[created updated], response.parsed_body.dig("event", "audit").pluck("action")
    assert_equal [ "Noche Live admin test", "Noche Live admin test" ], response.parsed_body.dig("event", "audit").pluck("actor")

    post publish_admin_api_ward_ward_event_path(ward.code, event_id),
         params: { actor: "Fausse présidence" },
         headers: auth_headers,
         as: :json
    assert_response :success
    assert_equal "published", response.parsed_body.dig("event", "status")
    assert_equal "Noche Live admin test", response.parsed_body.dig("event", "approved_by")
    assert_equal %w[created updated published], response.parsed_body.dig("event", "audit").pluck("action")
    assert_equal [ "Noche Live admin test" ] * 3, response.parsed_body.dig("event", "audit").pluck("actor")

    patch admin_api_ward_ward_event_path(ward.code, event_id),
          params: { actor: "Sœur Martin", title: "Texte non approuvé" },
          headers: auth_headers,
          as: :json
    assert_response :unprocessable_entity

    post cancel_admin_api_ward_ward_event_path(ward.code, event_id),
         params: { actor: "Encore une identité falsifiée", reason: "La salle n’est plus disponible" },
         headers: auth_headers,
         as: :json
    assert_response :success
    assert_equal "cancelled", response.parsed_body.dig("event", "status")
    assert_equal "La salle n’est plus disponible", response.parsed_body.dig("event", "cancellation_reason")
    assert_equal %w[created updated published cancelled], response.parsed_body.dig("event", "audit").pluck("action")
    assert_equal [ "Noche Live admin test" ] * 4, response.parsed_body.dig("event", "audit").pluck("actor")
    assert_not_includes response.parsed_body.dig("event", "audit").pluck("actor"), "Usurpatrice depuis le payload"
  end

  test "does not require a caller-controlled actor to create a ward event" do
    ward = wards(:demo)

    post admin_api_ward_ward_events_path(ward.code),
         params: ward_event_payload.except(:actor),
         headers: auth_headers,
         as: :json

    assert_response :created
    assert_equal "Noche Live admin test", response.parsed_body.dig("event", "audit", 0, "actor")
  end

  test "derives a stable server audit identity when no configured label is present" do
    configured_actor = ENV.delete("NOCHE_ADMIN_API_AUDIT_ACTOR")

    post admin_api_ward_ward_events_path(wards(:demo).code),
         params: ward_event_payload(actor: "Usurpateur depuis le payload"),
         headers: auth_headers,
         as: :json

    assert_response :created
    assert_equal "admin-token:#{OpenSSL::Digest::SHA256.hexdigest(TOKEN).first(16)}",
      response.parsed_body.dig("event", "audit", 0, "actor")
  ensure
    ENV["NOCHE_ADMIN_API_AUDIT_ACTOR"] = configured_actor
  end

  test "scopes the ward event API to the ward in the route" do
    other = wards(:blank)
    event = WardEvent.create_draft!(
      ward: other,
      attributes: ward_event_payload.except(:actor),
      actor: "Sœur Martin"
    )

    get admin_api_ward_ward_event_path(wards(:demo).code, event.id), headers: auth_headers

    assert_response :not_found
  end

  test "drafts previews and explicitly approves notification copy without sending" do
    assert_no_difference("NotificationDelivery.count") do
      post admin_api_notification_editorials_path,
           params: {
             editorial_key: "message.night-tomorrow.v1",
             proposal_type: "message",
             payload: {
               notification_kind: "night_tomorrow",
               translations: editorial_translations("Noche Live", "Rendez-vous à %{time}.")
             }
           },
           headers: auth_headers,
           as: :json
    end

    assert_response :created
    id = response.parsed_body.dig("proposal", "id")

    get preview_admin_api_notification_editorial_path(id), headers: auth_headers
    assert_response :success
    assert_equal false, response.parsed_body.fetch("delivery_enabled")
    assert_equal "Rendez-vous à 19:30.", response.parsed_body.dig("preview", "locales", "fr", "body")
    assert_equal "exact_noche_live_entry", response.parsed_body.dig("preview", "locales", "fr", "destination_rule")

    post approval_preview_admin_api_notification_editorial_path(id), headers: auth_headers, as: :json
    assert_response :success
    confirmation = response.parsed_body.fetch("confirmation")
    assert_match(/does not enable or send/, response.parsed_body.dig("approval", "effect"))

    post approve_admin_api_notification_editorial_path(id),
         params: { confirmation: },
         headers: auth_headers,
         as: :json
    assert_response :success
    assert_equal "approved", response.parsed_body.dig("proposal", "status")
    assert_equal false, response.parsed_body.fetch("delivery_enabled")

    patch admin_api_notification_editorial_path(id),
          params: { payload: { notification_kind: "night_tomorrow" } },
          headers: auth_headers,
          as: :json
    assert_response :unprocessable_entity
  end

  test "previews a dated verse in all four locales without scheduling it" do
    assert_no_difference("NotificationDelivery.count") do
      post admin_api_notification_editorials_path,
           params: {
             editorial_key: "verse.2026-09-01",
             proposal_type: "verse",
             payload: {
               publish_on: "2026-09-01",
               study: "nt/john/3",
               verse: 16,
               theme: "love"
             }
           },
           headers: auth_headers,
           as: :json
    end

    assert_response :created
    id = response.parsed_body.dig("proposal", "id")
    get preview_admin_api_notification_editorial_path(id), headers: auth_headers

    assert_response :success
    locales = response.parsed_body.dig("preview", "locales")
    assert_equal NotificationEditorialProposal::LOCALES.sort, locales.keys.sort
    assert_match %r{\A/fr/}, locales.dig("fr", "destination")
  end

  private

    def auth_headers
      { "Authorization" => "Bearer #{TOKEN}" }
    end

    def editorial_translations(title, body)
      NotificationEditorialProposal::LOCALES.to_h do |locale|
        [ locale, { title: "#{title} #{locale}", body: } ]
      end
    end

    def ward_event_payload(actor: "Sœur Martin")
      {
        actor:,
        kind: "food_drive",
        title: "Collecte alimentaire",
        summary: "Apportez des produits non périssables.",
        starts_at: 2.days.from_now.iso8601,
        ends_at: 2.days.from_now.advance(hours: 2).iso8601,
        location_label: "Salle paroissiale",
        destination_path: "/ramas/RAMA",
        artwork_path: "/media/church/worship.jpg"
      }
    end
end
