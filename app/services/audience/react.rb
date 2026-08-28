module Audience
  class React
    class Closed < StandardError; end
    class RateLimited < StandardError; end

    WINDOW = 2.seconds

    def self.call(night:, round:, audience_digest:, mark:, now: Time.current)
      new(night:, round:, audience_digest:, mark:, now:).call
    end

    def initialize(night:, round:, audience_digest:, mark:, now:)
      @night = night
      @round = round
      @audience_digest = audience_digest
      @mark = mark.to_s
      @now = now
    end

    def call
      snapshot = Snapshot.new(night: @night, now: @now)
      raise Closed unless snapshot.round == @round && snapshot.phase.in?(%w[open locked revealed])
      raise ActiveRecord::RecordInvalid, reaction unless AudienceReaction::MARKS.include?(@mark)
      raise RateLimited if @round.audience_reactions.where(audience_digest: @audience_digest).where(created_at: (@now - WINDOW)..).exists?

      reaction.save!
      @night.broadcast_state(pulse: { kind: "audience_reaction", mark: @mark })
      reaction
    end

    private

      def reaction
        @reaction ||= @round.audience_reactions.new(
          audience_digest: @audience_digest,
          mark: @mark,
          created_at: @now,
          updated_at: @now
        )
      end
  end
end
