module Notifications
  class PromptEligibility
    Result = Data.define(:eligible, :reason, :state)
    CONTEXT_CATEGORY = {
      "challenge_sent" => "challenges",
      "challenge_inbox" => "challenges",
      "challenge_result" => "challenges",
      "study_completed" => "verses",
      "live_upcoming" => "nights",
      "profile" => nil
    }.freeze

    def self.call(person:, device_token:, category:, context:, automatic: true, priority_blocked: false)
      new(person:, device_token:, category:, context:, automatic:, priority_blocked:).call
    end

    def initialize(person:, device_token:, category:, context:, automatic:, priority_blocked:)
      @person = person
      @device_token = device_token.to_s
      @category = category.to_s
      @context = context.to_s
      @automatic = automatic
      @priority_blocked = priority_blocked
    end

    def call
      return result(false, :feature_disabled) unless Notifications::Feature.enabled?
      return result(false, :guest) unless @person
      return result(false, :invalid_category) unless NotificationPromptState::CATEGORIES.include?(@category)
      return result(false, :invalid_context) unless NotificationPromptState::CONTEXTS.include?(@context)
      return result(false, :wrong_context) if @automatic && CONTEXT_CATEGORY[@context] != @category
      return result(false, :priority_action) if @priority_blocked

      preference = @person.notification_settings
      active = preference.public_send("#{@category}_enabled?")
      return result(false, :already_active) if active

      device = @person.person_devices.find_by(device_token: @device_token)
      return result(false, :device_missing) unless device
      return result(false, :system_denied) if device.notification_prompt_states.system_denied.exists?

      state = device.notification_prompt_states.find_by(category: @category)
      return result(false, :snoozed, state) if state&.snoozed?
      return result(false, :recently_offered, state) if @automatic && state&.last_offered_at&.after?(30.days.ago)

      result(true, :eligible, state)
    end

    private

      def result(eligible, reason, state = nil)
        Result.new(eligible:, reason:, state:)
      end
  end
end
