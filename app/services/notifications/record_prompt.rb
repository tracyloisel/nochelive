module Notifications
  class RecordPrompt
    RESULTS = (NotificationPromptState::RESULTS + [ "offered" ]).freeze

    def self.call(person:, device_token:, category:, result:, context:)
      new(person:, device_token:, category:, result:, context:).call
    end

    def initialize(person:, device_token:, category:, result:, context:)
      @person = person
      @device_token = device_token.to_s
      @category = category.to_s
      @result = result.to_s
      @context = context.to_s
    end

    def call
      raise ActiveRecord::RecordNotFound unless @person
      raise ArgumentError, "invalid category" unless NotificationPromptState::CATEGORIES.include?(@category)
      raise ArgumentError, "invalid result" unless RESULTS.include?(@result)
      raise ArgumentError, "invalid context" unless NotificationPromptState::CONTEXTS.include?(@context)

      device = @person.person_devices.find_by!(device_token: @device_token)
      state = device.notification_prompt_states.find_or_initialize_by(category: @category)
      state.last_offered_at = Time.current if @result == "offered" || state.last_offered_at.nil?
      state.offer_context = @context
      unless @result == "offered"
        state.last_result = @result
        state.snoozed_until = @result == "dismissed" ? NotificationPromptState::SNOOZE.from_now : nil
      end
      state.save!
      state
    end
  end
end
