require "test_helper"

class NotificationExperienceTest < ActionDispatch::IntegrationTest
  test "profile creation and the hub remain free of automatic push invitations" do
    with_web_push_enabled do
      sign_in_congregation
      create_street_profile!(name: "Onboarding Express")

      assert_response :success
      assert_select ".push-invitation", count: 0
      assert_select ".push-settings", count: 0
    end
  end

  test "the ficha exposes granular voluntary settings with no preselected category" do
    with_web_push_enabled do
      sign_in_congregation
      create_street_profile!(name: "Réglages Push")
      get street_profile_path(edit: 1)

      assert_response :success
      assert_select ".push-settings[data-controller='push-subscription']"
      assert_select ".push-category-card", count: 3
      assert_select "[data-push-subscription-challenges-active-value='false']"
      assert_select "[data-push-subscription-verses-active-value='false']"
      assert_select "[data-push-subscription-nights-active-value='false']"
      assert_select ".push-setting-toggle[role='switch'][aria-checked='false']", count: 3
      assert_select ".push-setting-toggle[role='switch'][aria-checked='true']", count: 3
      assert_select ".push-setting-toggle", text: /Réglages Push/, count: 0
      assert_select ".push-verse-options", count: 1
    end
  end

  test "the hamburger opens a dedicated notification settings screen" do
    with_web_push_enabled do
      sign_in_congregation
      create_street_profile!(name: "Menu Notifications")

      get root_path
      assert_response :success
      assert_select "a.home-menu-row[href='#{notification_settings_path}']", text: I18n.t("notifications.settings.menu")

      get notification_settings_path
      assert_response :success
      assert_select "#notification_settings h1", text: I18n.t("notifications.settings.menu")
      assert_select ".push-settings[data-controller='push-subscription']"
      assert_select ".push-category-card", count: 3
      assert_select ".push-category-list > .push-category-card", count: 3
    end
  end

  test "notification settings return a player to the screen after creating a ficha" do
    with_web_push_enabled do
      sign_in_congregation

      get notification_settings_path
      assert_redirected_to street_profile_path

      post street_profile_path, params: {
        name: "Retour Notifications",
        family_name: "Test",
        favorite_year: 2000,
        avatar_key: "tortuga",
        soy_nueva: 1
      }

      assert_redirected_to notification_settings_path
    end
  end

  test "an upcoming ward night offers its own consent only from the live context" do
    with_web_push_enabled do
      game_sessions(:david).update!(status: "finished")
      sign_in_congregation
      create_street_profile!(name: "Noche Demain")
      get root_path

      assert_response :success
      assert_select ".hub-live.is-soon, .hub-live.is-imminent, .hub-live.is-scheduled", count: 1
      assert_select ".push-invitation.is-nights", count: 1
      assert_select ".push-invitation.is-challenges", count: 0
      assert_select ".push-invitation.is-verses", count: 0
    end
  end

  test "a future session incorrectly marked playing does not suppress the Noche consent" do
    with_web_push_enabled do
      game_sessions(:david).update!(status: "playing", starts_at: 20.hours.from_now)
      game_sessions(:elias).update!(status: "lobby", starts_at: 21.hours.from_now)
      sign_in_congregation
      create_street_profile!(name: "Noche Prioritaire")

      get root_path

      assert_response :success
      assert_select ".hub-live.is-imminent", count: 1
      assert_select ".push-invitation.is-nights", count: 1
    end
  end

  test "a named challenge creates one contextual invitation only after the action" do
    with_web_push_enabled do
      sign_in_congregation
      create_street_profile!(name: "Défieur Contextuel")

      post street_challenges_path, params: { opponent_id: people(:carmen_garcia).id, pack_id: "coronas" }
      assert_redirected_to street_challenges_path
      follow_redirect!

      assert_select ".push-invitation.is-challenges", count: 1
      assert_select ".push-invitation .push-primary.btn-gold", count: 1
      assert_select ".push-invitation .quiet-link", text: I18n.t("notifications.prompt.not_now")
    end
  end

  test "settings disappear completely while the rollout flag is off" do
    with_web_push_disabled do
      sign_in_congregation
      create_street_profile!(name: "Flag Off")
      get street_profile_path(edit: 1)

      assert_response :success
      assert_select ".push-settings", count: 0
      assert_select ".push-invitation", count: 0

      get notification_settings_path
      assert_response :not_found
    end
  end

  private

  def with_web_push_disabled
    previous = ENV["WEB_PUSH_ENABLED"]
    ENV["WEB_PUSH_ENABLED"] = "false"
    yield
  ensure
    previous.nil? ? ENV.delete("WEB_PUSH_ENABLED") : ENV["WEB_PUSH_ENABLED"] = previous
  end
end
