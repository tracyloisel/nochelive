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

    def self.call(challenger_person:, ward:, pack_id:, device_digest: nil, run: nil, opponent_person: nil)
      new(challenger_person:, ward:, pack_id:, device_digest:, run:, opponent_person:).call
    end

    def initialize(challenger_person:, ward:, pack_id:, device_digest: nil, run: nil, opponent_person: nil)
      @challenger = challenger_person
      @ward = ward
      @pack_id = pack_id.to_s
      @run = run
      @digest = device_digest.to_s.presence || @run&.device_digest
      @opponent = opponent_person
    end

    def call
      raise ArgumentError, "unknown pack" unless QuizDefinition.catalog.pack_ids.include?(@pack_id)
      raise Denied, :self if @opponent && @opponent.id == @challenger.id
      raise Denied, :stake if @opponent && !StakeScope.allowed?(challenger_ward: @ward, opponent_ward: @opponent.ward)

      existing = find_existing
      if existing
        ensure_challenger_run!(existing)
        return Result.new(duel: existing.reload, share_url: share_path_for(existing))
      end

      duel = ApplicationRecord.transaction do
        row = StreetDuel.create!(
          challenger_person: @challenger,
          opponent_person: @opponent,
          ward: @ward,
          challenger_ward: @ward,
          opponent_ward: @opponent&.ward,
          stake_unit_id: @ward.stake_unit_id,
          pack_id: @pack_id,
          token: SecureRandom.urlsafe_base64(12),
          status: "pending",
          expires_at: 7.days.from_now
        )
        ensure_challenger_run!(row)
        row.reload
      end
      Quizzes::ChallengeNotify.call(duel:) if @opponent
      Result.new(duel:, share_url: share_path_for(duel))
    end

    private

      def find_existing
        scope = StreetDuel.active.not_expired.where(pack_id: @pack_id)
        if @opponent
          scope.where(
            "(challenger_person_id = :a AND opponent_person_id = :b) OR (challenger_person_id = :b AND opponent_person_id = :a)",
            a: @challenger.id, b: @opponent.id
          ).first
        else
          scope.find_by(challenger_person_id: @challenger.id, opponent_person_id: nil)
        end
      end

      def ensure_challenger_run!(duel)
        return if duel.challenger_run_id.present?

        if @run&.finished?
          @run.update!(street_duel: duel)
          duel.update!(challenger_run: @run, challenger_score: @run.score, status: "challenger_done")
          return
        end
        raise ArgumentError, "device required" if @digest.blank?

        frame = StartPack.call(
          device_digest: @digest,
          person_id: @challenger.id,
          pack_id: @pack_id,
          challenge: true,
          street_duel: duel
        )
        duel.update!(challenger_run: frame.run)
      end

      def share_path_for(duel)
        Rails.application.routes.url_helpers.street_challenge_path(duel.token)
      end
  end
end
