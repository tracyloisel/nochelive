module Audience
  class Respond
    class Closed < StandardError; end
    class InvalidChoice < StandardError; end

    def self.call(night:, round:, audience_digest:, choice:, now: Time.current)
      new(night:, round:, audience_digest:, choice:, now:).call
    end

    def initialize(night:, round:, audience_digest:, choice:, now:)
      @night = night
      @round = round
      @audience_digest = audience_digest
      @choice = choice.to_s
      @now = now
    end

    def call
      snapshot = Snapshot.new(night: @night, now: @now)
      raise Closed unless snapshot.round == @round && snapshot.accepting_responses?
      raise InvalidChoice unless allowed_choices.include?(@choice)

      response = @round.audience_responses.find_or_initialize_by(audience_digest: @audience_digest)
      return response if response.persisted?

      response.choice = @choice
      response.answered_at = @now
      response.save!
      response
    rescue ActiveRecord::RecordNotUnique
      @round.audience_responses.find_by!(audience_digest: @audience_digest)
    end

    private

      def allowed_choices
        Array(@round.definition.choices).map do |choice|
          if choice.is_a?(Hash)
            (choice["key"] || choice[:key] || choice["label"] || choice[:label]).to_s
          else
            choice.to_s
          end
        end
      end
  end
end
