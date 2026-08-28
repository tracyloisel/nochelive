class PublicController < ApplicationController
  before_action :set_public_night

  def show
    @snapshot = Audience::Snapshot.new(night: @night)
    @round = @snapshot.round
    @audience_digest = audience_digest
    @response = @round&.audience_responses&.find_by(audience_digest: @audience_digest)
    @distribution = response_distribution
    @response_count = @round&.audience_responses&.count.to_i
    @streak = audience_streak
  end

  private

    def set_public_night
      @night = GameSession.find_by!(public_token: params[:public_token])
    end

    def response_distribution
      return {} unless @round && @snapshot.reveal_visible?

      counts = @round.audience_responses.group(:choice).count
      total = counts.values.sum
      counts.transform_values { |count| total.zero? ? 0 : ((count * 100.0) / total).round }
    end

    def audience_streak
      responses = @night.audience_responses
        .where(audience_digest: @audience_digest)
        .includes(:round_run)
        .order(answered_at: :desc)

      responses.take_while(&:correct?).size
    end
end
