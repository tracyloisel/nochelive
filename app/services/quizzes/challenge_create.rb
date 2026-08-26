module Quizzes
  class ChallengeCreate
    Result = Struct.new(:duel, :share_url, keyword_init: true)

    def self.call(challenger_person:, ward:, pack_id:, run: nil)
      new(challenger_person:, ward:, pack_id:, run:).call
    end

    def initialize(challenger_person:, ward:, pack_id:, run: nil)
      @challenger = challenger_person
      @ward = ward
      @pack_id = pack_id.to_s
      @run = run
    end

    def call
      status = @run&.finished? ? "challenger_done" : "pending"
      duel = StreetDuel.create!(
        challenger_person: @challenger,
        ward: @ward,
        pack_id: @pack_id,
        token: SecureRandom.urlsafe_base64(12),
        status:,
        challenger_run: @run,
        challenger_score: @run&.finished? ? @run.score : nil,
        expires_at: 7.days.from_now
      )
      Result.new(duel:, share_url: share_path_for(duel))
    end

    private

      def share_path_for(duel)
        Rails.application.routes.url_helpers.street_challenge_url(
          duel.token,
          host: ENV.fetch("APP_HOST", "www.example.com")
        )
      end
  end
end
