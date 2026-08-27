require "test_helper"
require "view_component/test_case"

class Navigation::DockComponentTest < ViewComponent::TestCase
  test "renders the five game destinations and marks the active one" do
    render_inline(Navigation::DockComponent.new(active: :profile))

    assert_selector "nav.street-hub-nav.street-world-dock"
    assert_selector "a.street-hub-nav-item", count: 5
    assert_selector "a.street-hub-nav-item.is-active", text: I18n.t("hub.nav_profile")
    parole = Rails.application.routes.url_helpers.study_program_path
    assert_selector "a.street-hub-nav-item.is-word[href='#{parole}']"
    assert_selector ".street-hub-word-medallion .picto-scripture-book"
  end

  test "marks the word destination active" do
    render_inline(Navigation::DockComponent.new(active: :word))

    assert_selector "a.street-hub-nav-item.is-word.is-active[href='/parole']"
  end

end
