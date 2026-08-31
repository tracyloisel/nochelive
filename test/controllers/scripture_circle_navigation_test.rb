require "test_helper"

class ScriptureCircleNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @person = people(:pili)
    @program = StudyProgram.create!(
      slug: "circle-navigation-#{SecureRandom.hex(4)}",
      title: "Viens et suis-moi 2026",
      year: 2026,
      canon: "old_testament",
      locale: "fr",
      status: "published",
      source_url: "https://example.test/circle-navigation"
    )
  end

  test "makes the ward Circle the one social exit from the library" do
    sign_in_person(@person)

    get scripture_library_path(locale: :fr)

    assert_response :success
    assert_select ".scripture-library-row[data-library-row='rama'][href=?]",
      scripture_circle_path(locale: :fr), count: 1
    assert_select ".chrome-drawer a.home-menu-row[href=?]", scripture_circle_path(locale: :fr), count: 0
  end

  test "does not advertise a Circle that the player's ward has closed" do
    @ward.update!(scripture_circle_mode: "disabled")
    sign_in_person(@person)

    get scripture_library_path(locale: :fr)

    assert_response :success
    assert_select ".scripture-library-row[data-library-row='rama'].is-disabled[aria-disabled='true']", count: 1
    assert_select ".scripture-library-row[data-library-row='rama'][href]", count: 0
    assert_select ".chrome-drawer a.home-menu-row[href=?]", scripture_circle_path(locale: :fr), count: 0
  end

  test "keeps the Circle reachable when the ward has made it read only" do
    @ward.update!(scripture_circle_mode: "read_only")
    sign_in_person(@person)

    get scripture_library_path(locale: :fr)

    assert_response :success
    assert_select ".scripture-library-row[data-library-row='rama'][href=?]",
      scripture_circle_path(locale: :fr), count: 1
    assert_select ".chrome-drawer a.home-menu-row[href=?]", scripture_circle_path(locale: :fr), count: 0
  end

  private

    def sign_in_person(person, token: "circle-navigation-device")
      person.person_devices.find_or_create_by!(device_token: token)
      set_signed_cookie(:noche_device, token)
      set_signed_cookie(:noche_ward, person.ward_id)
      set_signed_cookie(:noche_street_person, person.id)
    end

    def set_signed_cookie(name, value)
      signed_value = signed_cookie_jar.tap { |jar| jar.signed[name] = value }[name]
      uri = URI("http://#{host}/")
      cookies.merge("#{name}=#{Rack::Utils.escape(signed_value)}; path=/", uri)
    end

    def signed_cookie_jar(values = {})
      ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, values)
    end
end
