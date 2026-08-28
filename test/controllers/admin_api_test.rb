require "test_helper"

class AdminApiTest < ActionDispatch::IntegrationTest
  TOKEN = "admin-test-token-that-is-at-least-32-characters"

  setup do
    @previous_token = ENV["NOCHE_ADMIN_API_TOKEN"]
    ENV["NOCHE_ADMIN_API_TOKEN"] = TOKEN
  end

  teardown do
    ENV["NOCHE_ADMIN_API_TOKEN"] = @previous_token
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

  test "rotates a presenter code and returns it only in the response" do
    ward = wards(:demo)

    post rotate_presenter_token_admin_api_ward_path(ward.code), headers: auth_headers

    assert_response :success
    token = response.parsed_body.fetch("presenter_token")
    assert ward.reload.presenter_token_matches?(token)
    assert_not ward.presenter_token_matches?("rama-demo")
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
             starts_at: "2026-08-30T19:30:00+02:00",
             presenter_locale: "fr",
             broadcast_delay_ms: 1_500,
             missionary_names: [ "Sœur Martin", "Élder Silva" ]
           },
           headers: auth_headers,
           as: :json
    end

    assert_response :created
    code = response.parsed_body.dig("night", "code")
    night = ward.game_sessions.find_by!(code:)
    assert_equal "fr", night.presenter_locale
    assert_equal 1_500, night.broadcast_delay_ms
    assert_equal [ "Sœur Martin", "Élder Silva" ], night.missionaries.order(:id).pluck(:name)
    assert_equal "/s/#{code}/name", response.parsed_body.dig("night", "paths", "players")

    patch admin_api_ward_night_path(ward.code, code),
          params: {
            starts_at: "2026-08-30T20:00:00+02:00",
            presenter_locale: "es",
            missionary_names: [ "Sœur Martin" ]
          },
          headers: auth_headers,
          as: :json

    assert_response :success
    assert_equal "es", night.reload.presenter_locale
    assert_equal 20, night.starts_at.in_time_zone("Europe/Madrid").hour
    assert_equal [ "Sœur Martin" ], night.missionaries.pluck(:name)
  end

  test "cannot edit a Noche Live through another ward" do
    patch admin_api_ward_night_path(wards(:blank).code, game_sessions(:david).code),
          params: { presenter_locale: "fr" },
          headers: auth_headers,
          as: :json

    assert_response :not_found
    assert_equal "es", game_sessions(:david).reload.presenter_locale
  end

  test "rejects invalid Noche Live configuration" do
    post admin_api_ward_nights_path(wards(:blank).code),
         params: { starts_at: "tomorrow evening", presenter_locale: "de" },
         headers: auth_headers,
         as: :json

    assert_response :unprocessable_entity
  end

  private

    def auth_headers
      { "Authorization" => "Bearer #{TOKEN}" }
    end
end
