require "test_helper"

class ProgressiveStreetIdentityTest < ActionDispatch::IntegrationTest
  test "a first visitor gets the essential Hub and an honest ward invitation" do
    get root_path

    assert_response :success
    assert_select "#profile_gate", count: 0
    assert_select ".street-hub-feed"
    assert_select ".navigation-dock"
    assert_select "a.quiz-hud-who.is-guest[href=?]", street_profile_path(fresh: 1)
    assert_select ".hub-live.hub-live--feature.is-ward_missing", count: 1
    assert_select "a.hub-live-program.is-ward-pick[href=?]",
      street_profile_path(quick: 1, fresh: 1, ward_next: 1) do
      assert_select "span", text: I18n.t("hub.pick_ward_cta")
    end
    assert_select ".hub-live-ward-title", text: I18n.t("hub.pick_ward_title")
    assert_select ".hub-now", count: 0
    assert_select ".street-hub-feed > section.hub-rama-carousel.hub-rama-block", count: 1
    assert_select ".street-hub-feed > section.hub-rama-carousel.hub-rama-block", count: 1 do
      assert_select ".hub-rama-carousel__track > a.hub-rama-card--challenge[href=?]", street_challenges_path, count: 1
      assert_select ".hub-rama-carousel__track > a.hub-rama-card--videos[href=?]", church_videos_path(locale: I18n.locale), count: 1
    end
    assert_select ".hub-identity-empty", count: 0
  end


  test "ward invitation creates a named profile before opening ward discovery" do
    get street_profile_path(quick: 1, fresh: 1, ward_next: 1)
    assert_response :success
    assert_select "h1", text: I18n.t("street.quick_profile_title")

    assert_difference -> { Person.count }, 1 do
      post street_profile_path(quick: 1, ward_next: 1), params: { name: "Lina", avatar_key: "delfin" }
    end

    assert_redirected_to search_path(cambiar: 1)
    assert_equal "Lina", Person.order(:id).last.given_name
  end

  test "a profiled player without a real next action does not receive fabricated Hub cards" do
    post street_profile_path, params: { name: "Lina", avatar_key: "delfin" }
    assert_redirected_to root_path
    follow_redirect!

    assert_select ".hub-live.hub-live--feature.is-ward_missing", count: 1
    assert_select "a.hub-live-program.is-ward-pick[href=?]",
      search_path(cambiar: 1)
    assert_select ".hub-now", count: 0
    assert_select ".street-hub-feed > section.hub-rama-carousel.hub-rama-block", count: 1
    assert_select ".street-hub-feed > section.hub-rama-carousel.hub-rama-block", count: 1 do
      assert_select ".hub-rama-carousel__track > a.hub-rama-card--challenge[href=?]", street_challenges_path, count: 1
      assert_select ".hub-rama-carousel__track > a.hub-rama-card--videos[href=?]", church_videos_path(locale: I18n.locale), count: 1
    end
    assert_select ".hub-identity-empty", count: 0
  end

  test "the hub paints one preloaded narrative background" do
    get root_path

    assert_response :success
    assert_select "body.is-game-hub-page"
    assert_select "#street_world.is-opening", count: 0
    assert_select "#street_world[data-controller~='hub-open']", count: 0
    assert_select ".hub-hero[data-controller~='hub-hero']", count: 0
    # Only the actual hero is urgent: the responsive <picture> itself is eager
    # and this preload keeps the current source on the LCP path without making
    # any secondary Hub section compete for the first viewport's bandwidth.
    assert_select "link[rel=preload][as=image][fetchpriority=high]", minimum: 1
    assert_select ".hub-slide.is-current img[loading=eager][fetchpriority=high]", count: 1

    css = frontend_css("hub")
    hub_sky = css[/body\.is-street-hub\.is-game-hub-page \.sky \{[^}]+\}/m]
    assert hub_sky
    assert_match(/background:\s*none/, hub_sky)
    refute_match(/\.street-world\.is-game-hub\.is-opening::before\s*\{[^}]*opacity:\s*0/m, css)
    assert_select ".street-hub-feed .hub-hero[data-controller='hub-portal']", count: 1
    assert_select ".street-hub-feed .hub-hero .hub-slide", count: 1
    assert_select ".street-hub-feed .hub-voyage-nav, .street-hub-feed .hub-dot", count: 0
    assert_match(/\.hub-streaming-feed--editorial\s*\{/, css)
    assert_match(/\.hub-live--feature/, css)

    refute_match(/\.hub-slide\.is-current \.hub-slide-still\s*\{[^}]*animation:/m, css)
    refute_match(/\.hub-reward-chest\.is-sheening/, css)
    refute_match(/\.hub-play\.is-idle-sheen/, css)
  end

  test "playing asks only for a name then resumes the requested pack" do
    post street_pack_start_path("coronas")

    assert_redirected_to street_profile_path(quick: 1, fresh: 1)
    follow_redirect!
    assert_select "h1", text: I18n.t("street.quick_profile_title")
    assert_select "input[name=name]"
    assert_select ".profile-later", text: I18n.t("street.avatar_automatic")
    assert_select "input[name=favorite_year]", count: 0
    assert_select ".avatar-pick", count: 0

    assert_difference -> { Person.count }, 1 do
      post street_profile_path(quick: 1), params: { name: "Noa", avatar_key: "delfin" }
    end

    person = Person.order(:id).last
    assert_nil person.ward
    assert_nil person.favorite_year
    assert_redirected_to jugar_path
    follow_redirect!
    assert_select "#street_quiz"
    assert_equal person.id, QuizRun.order(:id).last.person_id
  end
end
