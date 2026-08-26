module Quizzes
  class ChallengeCreate
    Result = Struct.new(:duel, :share_url, keyword_init: true)
    class Denied < StandardError
      attr_reader :code

      def initialize(code)
        @code = code.to_sym
        super(code.to_s)
      end
    end

    def self.call(challenger_person:, ward:, pack_id:, run: nil, opponent_person: nil)
      new(challenger_person:, ward:, pack_id:, run:, opponent_person:).call
    end

    def initialize(challenger_person:, ward:, pack_id:, run: nil, opponent_person: nil)
      @challenger = challenger_person
      @ward = ward
      @pack_id = pack_id.to_s
      @run = run
      @opponent = opponent_person
    end

    def call
      raise ArgumentError, "unknown pack" unless QuizDefinition.catalog.pack_ids.include?(@pack_id)
      raise Denied, :self if @opponent && @opponent.id == @challenger.id
      raise Denied, :ward if @opponent && @opponent.ward_id != @ward.id
      raise Denied, :score if @opponent && !@run&.finished?

      existing = find_existing
      if existing
        attach_run!(existing)
        return Result.new(duel: existing.reload, share_url: share_path_for(existing))
      end

      finished = @run&.finished?
      duel = StreetDuel.create!(
        challenger_person: @challenger,
        opponent_person: @opponent,
        ward: @ward,
        pack_id: @pack_id,
        token: SecureRandom.urlsafe_base64(12),
        status: finished ? "challenger_done" : "pending",
        challenger_run: finished ? @run : nil,
        challenger_score: finished ? @run.score : nil,
        expires_at: 7.days.from_now
      )
      Result.new(duel:, share_url: share_path_for(duel))
    end

    private

      def find_existing
        scope = StreetDuel.active.not_expired.where(
          challenger_person_id: @challenger.id,
          pack_id: @pack_id
        )
        if @opponent
          scope.find_by(opponent_person_id: @opponent.id)
        else
          scope.find_by(opponent_person_id: nil)
        end
      end

      def attach_run!(duel)
        return unless @run&.finished?
        return if duel.challenger_run_id.present?

        duel.update!(
          challenger_run: @run,
          challenger_score: @run.score,
          status: duel.pending? ? "challenger_done" : duel.status
        )
      end

      def share_path_for(duel)
        Rails.application.routes.url_helpers.street_challenge_path(duel.token)
      end
  end
end
