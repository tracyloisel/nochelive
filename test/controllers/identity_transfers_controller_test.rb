require "test_helper"

class IdentityTransfersControllerTest < ActionDispatch::IntegrationTest
  test "durable identity moves once from Render to the custom domain" do
    host! "nochelive.onrender.com"
    people(:carmen_garcia).person_devices.find_or_create_by!(device_token: "device-token")
    set_signed_cookie(:noche_device, "device-token")
    set_signed_cookie(:noche_ward, wards(:demo).id)
    set_signed_cookie(:noche_street_person, people(:carmen_garcia).id)
    cookies[Locale::COOKIE] = "fr"

    post identity_transfer_path

    assert_response :see_other
    token = Rack::Utils.parse_query(URI.parse(response.location).query).fetch("token")
    assert_equal "nochelive.com", URI.parse(response.location).host

    %w[noche_device noche_ward noche_street_person noche_locale].each { |name| cookies.delete(name) }
    host! "nochelive.com"
    get identity_transfer_claim_path, params: { token: token }

    assert_response :see_other
    assert_equal "device-token", read_signed_cookie(:noche_device)
    assert_equal wards(:demo).id, read_signed_cookie(:noche_ward)
    assert_equal people(:carmen_garcia).id, read_signed_cookie(:noche_street_person)
    assert_equal "fr", cookies[Locale::COOKIE]

    get identity_transfer_claim_path, params: { token: token }
    assert_response :see_other
    assert_equal 0, IdentityTransfer.count
  end

  test "a different profile on the custom domain is shown before anything changes" do
    token = issue_transfer(
      person: people(:carmen_garcia),
      device_token: "legacy-carmen-device"
    )
    sign_in_target(
      person: people(:carmen_lopez),
      device_token: "recent-carmen-device"
    )

    assert_no_changes -> { Person.count } do
      get identity_transfer_claim_path, params: { token: token }
    end

    assert_response :success
    assert_equal 1, IdentityTransfer.count
    assert_equal "recent-carmen-device", read_signed_cookie(:noche_device)
    assert_equal people(:carmen_lopez).id, read_signed_cookie(:noche_street_person)
    assert_select "dialog.identity-merge-modal"
    assert_select ".identity-merge-profile", count: 2
    assert_select "form[action='#{identity_transfer_merge_path}']"
    assert_select ".identity-merge-keep[href='#{root_path}']"
  end

  test "confirmed migration merges both profiles and preserves the target device" do
    legacy = people(:carmen_garcia)
    recent = people(:carmen_lopez)
    legacy.update_column(:created_at, 2.years.ago)
    recent.update_column(:created_at, 1.day.ago)
    token = issue_transfer(person: legacy, device_token: "legacy-carmen-device")
    sign_in_target(person: recent, device_token: "recent-carmen-device")

    assert_difference("Person.count", -1) do
      post identity_transfer_merge_path, params: { token: token }
    end

    assert_response :see_other
    assert_equal "https://nochelive.com/", response.location
    assert Person.exists?(legacy.id)
    assert_not Person.exists?(recent.id)
    assert_equal legacy.id, read_signed_cookie(:noche_street_person)
    assert_equal "recent-carmen-device", read_signed_cookie(:noche_device)
    assert PersonDevice.exists?(person: legacy, device_token: "legacy-carmen-device")
    assert PersonDevice.exists?(person: legacy, device_token: "recent-carmen-device")
    assert_equal 0, IdentityTransfer.count
  end

  test "incompatible profiles are never overwritten or offered an automatic merge" do
    token = issue_transfer(
      person: people(:carmen_garcia),
      device_token: "legacy-carmen-device"
    )
    sign_in_target(person: people(:pili), device_token: "pili-target-device")

    get identity_transfer_claim_path, params: { token: token }

    assert_response :success
    assert_equal people(:pili).id, read_signed_cookie(:noche_street_person)
    assert_equal "pili-target-device", read_signed_cookie(:noche_device)
    assert_equal 1, IdentityTransfer.count
    assert_select ".identity-merge-error", text: I18n.t("identity_migration.cannot_merge")
    assert_select "form[action='#{identity_transfer_merge_path}']", count: 0
    assert_select ".identity-merge-keep[href='#{root_path}']"

    assert_no_changes -> { Person.count } do
      post identity_transfer_merge_path, params: { token: token }
    end
    assert_response :unprocessable_entity
    assert Person.exists?(people(:carmen_garcia).id)
    assert Person.exists?(people(:pili).id)
    assert_equal 1, IdentityTransfer.count
  end

  test "the same profile on both domains keeps the current target device" do
    person = people(:carmen_garcia)
    token = issue_transfer(person:, device_token: "legacy-carmen-device")
    sign_in_target(person:, device_token: "current-target-device")

    get identity_transfer_claim_path, params: { token: token }

    assert_response :see_other
    assert_equal person.id, read_signed_cookie(:noche_street_person)
    assert_equal "current-target-device", read_signed_cookie(:noche_device)
    assert_equal 0, IdentityTransfer.count
  end

  test "privileged and temporary cookies are excluded from the payload" do
    host! "nochelive.onrender.com"
    set_signed_cookie(:noche_presenter, game_sessions(:david).id)
    set_signed_cookie(:noche_ward_host, wards(:demo).id)
    set_signed_cookie(:noche_player, 123)

    post identity_transfer_path

    token = Rack::Utils.parse_query(URI.parse(response.location).query).fetch("token")
    assert_empty IdentityTransfer.consume!(token).fetch("signed")
  end

  test "the issuer is unavailable on the custom domain" do
    host! "nochelive.com"

    post identity_transfer_path

    assert_response :not_found
  end

  test "the claim is unavailable on the Render domain" do
    host! "nochelive.onrender.com"

    get identity_transfer_claim_path, params: { token: "anything" }

    assert_response :not_found
  end

  test "an identified visitor sees the migration action only on the Render domain" do
    host! "nochelive.onrender.com"
    set_signed_cookie(:noche_device, "device-token")

    get root_path

    assert_select "dialog.identity-transfer-modal[open][aria-modal='true'][data-controller='identity-transfer']" do
      assert_select "h2#identity_transfer_title", text: I18n.t("identity_migration.title")
      assert_select "p#identity_transfer_hint", text: I18n.t("identity_migration.hint")
      assert_select ".identity-transfer-route", text: /#{Regexp.escape(IdentityTransfersController::TARGET_HOST)}/
      assert_select "button, a", count: 1
    end
    assert_select "form[action='#{identity_transfer_path}'][method='post'][data-turbo='false'][data-action='submit->identity-transfer#submit']"
    assert_select "form[action='#{identity_transfer_path}'] button.identity-transfer-cta" do
      assert_select "span", text: I18n.t("identity_migration.action")
    end

    host! "nochelive.com"
    get root_path

    assert_select "form[action='#{identity_transfer_path}']", count: 0
  end

  private

    def issue_transfer(person:, device_token:)
      host! IdentityTransfersController::SOURCE_HOST
      person.person_devices.find_or_create_by!(device_token: device_token)
      set_signed_cookie(:noche_device, device_token)
      set_signed_cookie(:noche_ward, person.ward_id)
      set_signed_cookie(:noche_street_person, person.id)

      post identity_transfer_path
      Rack::Utils.parse_query(URI.parse(response.location).query).fetch("token")
    ensure
      IdentityTransfersController::SIGNED_COOKIE_LIFETIMES.each_key { |name| cookies.delete(name) }
    end

    def sign_in_target(person:, device_token:)
      host! IdentityTransfersController::TARGET_HOST
      person.person_devices.find_or_create_by!(device_token: device_token)
      set_signed_cookie(:noche_device, device_token)
      set_signed_cookie(:noche_ward, person.ward_id)
      set_signed_cookie(:noche_street_person, person.id)
    end

    def set_signed_cookie(name, value)
      signed_value = signed_cookie_jar.tap { |jar| jar.signed[name] = value }[name]
      uri = URI("http://#{host}/")
      cookies.merge("#{name}=#{Rack::Utils.escape(signed_value)}; path=/", uri)
    end

    def read_signed_cookie(name)
      uri = URI("http://#{host}/")
      values = Rack::Utils.parse_cookies_header(cookies.for(uri))
      signed_cookie_jar(values).signed[name]
    end

    def signed_cookie_jar(values = {})
      ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, values)
    end
end
