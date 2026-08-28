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
      person = create_street_profile!(name: "Réglages Push")
      get street_profile_path(edit: 1)

      assert_response :success
      assert_select ".push-settings[data-controller='push-subscription']"
      assert_select ".push-category-card", count: 2
      assert_select "[data-push-subscription-challenges-active-value='false']"
      assert_select "[data-push-subscription-verses-active-value='false']"
      assert_select "button[data-category='challenges']", text: /#{Regexp.escape(person.given_name)}/
      assert_select "button[data-category='verses'][data-template*='__FREQUENCY__'][data-template*='__TIME__']"
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
    sign_in_congregation
    create_street_profile!(name: "Flag Off")
    get street_profile_path(edit: 1)

    assert_response :success
    assert_select ".push-settings", count: 0
    assert_select ".push-invitation", count: 0
  end
end
