require "application_system_test_case"

class StreetProfileVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "ficha keeps change ward visible without competing with save" do
    sign_in_fixture_person_direct!(people(:pili))

    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      visit street_profile_path(edit: 1)

      assert_selector ".profile-rama-current", text: people(:pili).ward.name
      assert_selector "a.profile-rama-change[href='#{search_path(cambiar: 1)}']", text: I18n.t("street.change_ward_short")
      assert_no_selector "a.profile-rama-change .picto"
      assert_selector ".profile-edit-form .btn-gold", text: I18n.t("street.save_profile")
      assert_profile_ward_switch_geometry!
      shot("profile-ward-switch-#{width}x#{height}")
      assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end

    find("a.profile-rama-change").click
    assert_current_path search_path(cambiar: 1)
    assert_selector "h1", text: I18n.t("street.change_ward")
  end

  private

    def sign_in_fixture_person_direct!(person)
      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.post enter_ward_path, params: { code: person.ward.code }
      session.post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }

      page.driver.browser.manage.delete_all_cookies
      visit root_path
      session.cookies.to_hash.each do |name, value|
        page.driver.browser.manage.add_cookie(name:, value:, path: "/")
      end
    end

    def assert_profile_ward_switch_geometry!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var link = document.querySelector(".profile-rama-change").getBoundingClientRect();
          var badge = document.querySelector(".profile-rama-switcher").getBoundingClientRect();
          return {
            linkWidth: link.width,
            linkHeight: link.height,
            badgeLeft: badge.left,
            badgeRight: badge.right,
            viewportWidth: window.innerWidth,
            bodyOverflow: document.documentElement.scrollWidth > window.innerWidth + 1
          };
        })()
      JS

      assert_operator geometry["linkWidth"], :<, 72
      assert_operator geometry["linkHeight"], :<, 28
      assert_operator geometry["badgeLeft"], :>=, -1
      assert_operator geometry["badgeRight"], :<=, geometry["viewportWidth"] + 1
      assert_not geometry["bodyOverflow"]
    end

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      path = SHOT_DIR.join("#{name}.png")
      page.save_screenshot(path)
      warn "street-profile-shot #{path}"
    end
end
