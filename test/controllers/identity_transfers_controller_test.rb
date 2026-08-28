require "test_helper"

class IdentityTransfersControllerTest < ActionDispatch::IntegrationTest
  test "durable identity moves once from Render to the custom domain" do
    host! "nochelive.onrender.com"
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

  private

    def set_signed_cookie(name, value)
      cookies[name] = signed_cookie_jar.tap { |jar| jar.signed[name] = value }[name]
    end

    def read_signed_cookie(name)
      signed_cookie_jar(cookies.to_hash).signed[name]
    end

    def signed_cookie_jar(values = {})
      ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, values)
    end
end
