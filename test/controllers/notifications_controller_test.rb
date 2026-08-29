require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def subscription_payload(endpoint: "https://push.example.test/controller")
    {
      subscription: { endpoint:, keys: { p256dh: "controller-p256dh", auth: "controller-auth" } },
      time_zone: "Europe/Madrid",
      category: "challenges",
      context: "profile"
    }
  end

  test "requires the feature flag and a persistent ficha" do
    previous = ENV["WEB_PUSH_ENABLED"]
    ENV["WEB_PUSH_ENABLED"] = "false"
    begin
      post notifications_subscription_path, params: subscription_payload
      assert_response :not_found
    ensure
      previous.nil? ? ENV.delete("WEB_PUSH_ENABLED") : ENV["WEB_PUSH_ENABLED"] = previous
    end

    with_web_push_enabled do
      post notifications_subscription_path, params: subscription_payload
      assert_response :unauthorized
    end
  end

  test "subscribes explicitly to only one category then updates and removes the device" do
    with_web_push_enabled do
      person = sign_in_new_profile

      assert_difference -> { WebPushSubscription.count }, 1 do
        post notifications_subscription_path, params: subscription_payload
      end
      assert_response :created
      assert person.notification_preference.reload.challenges_enabled?
      refute person.notification_preference.verses_enabled?
      refute_includes person.web_push_subscriptions.last.endpoint_ciphertext, "push.example.test"

      patch notifications_preferences_path, params: {
        category: "verses", enabled: true,
        verse_frequency: "daily", verse_local_time: "07:45"
      }
      assert_response :success
      assert person.notification_preference.reload.verses_enabled?
      assert_equal "daily", person.notification_preference.verse_frequency

      delete notifications_subscription_path, params: { endpoint: "https://push.example.test/controller" }
      assert_response :success
      assert_empty person.web_push_subscriptions.reload
      assert person.notification_preference.reload.challenges_enabled?
      assert person.notification_preference.verses_enabled?
    end
  end

  test "a shared browser requires an explicit reassignment confirmation" do
    with_web_push_enabled do
      person = sign_in_new_profile
      endpoint = web_push_subscriptions(:carmen_phone_push).endpoint

      post notifications_subscription_path, params: subscription_payload(endpoint:)
      assert_response :conflict
      assert_equal people(:carmen_garcia), web_push_subscriptions(:carmen_phone_push).reload.person

      post notifications_subscription_path, params: subscription_payload(endpoint:).merge(reassign: true)
      assert_response :created
      assert_equal person, web_push_subscriptions(:carmen_phone_push).reload.person
    end
  end

  test "records a thirty day per-category snooze" do
    freeze_time do
      with_web_push_enabled do
        person = sign_in_new_profile
        patch notifications_prompt_state_path, params: {
          category: "verses", result: "dismissed", context: "study_completed"
        }

        assert_response :success
        state = person.person_devices.last.notification_prompt_states.find_by!(category: "verses")
        assert_equal 30.days.from_now, state.snoozed_until
        assert_equal "dismissed", state.last_result
      end
    end
  end

  test "the deep-link request marks an opening without an intermediate redirect" do
    with_web_push_enabled do
      person = sign_in_new_profile
      post notifications_subscription_path, params: subscription_payload
      subscription = person.web_push_subscriptions.last
      delivery = NotificationDelivery.create!(
        web_push_subscription: subscription, person:, kind: "study_reading",
        dedupe_key: "controller-deep-link", destination: privacy_path, status: "sent"
      )

      get privacy_path(nl_delivery: delivery.id)

      assert_response :success
      assert delivery.reload.opened?
      assert delivery.opened_at
    end
  end

  test "Rails CSRF protection rejects a forged subscription request" do
    with_web_push_enabled do
      sign_in_new_profile
      previous = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      post notifications_subscription_path, params: subscription_payload
      assert_response :unprocessable_entity
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end
  end

  private

    def sign_in_new_profile
      sign_in_congregation
      create_street_profile!(name: "Push Player #{SecureRandom.hex(3)}")
    end
end
