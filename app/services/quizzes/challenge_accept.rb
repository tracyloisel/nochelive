module Quizzes
  class ChallengeAccept
    class Expired < StandardError; end
    class Taken < StandardError; end

    def self.call(duel:, opponent_person:, device_digest:)
      new(duel:, opponent_person:, device_digest:).call
    end

    def initialize(duel:, opponent_person:, device_digest:)
      @duel = duel
      @opponent = opponent_person
      @digest = device_digest
    end

    def call
      raise Expired, "duel expired" if @duel.expired?
      raise Taken, "duel resolved" if @duel.resolved? || @duel.declined?

      ApplicationRecord.transaction do
        locked = StreetDuel.lock.find(@duel.id)
        raise Expired, "duel expired" if locked.expired?
        raise Taken, "duel resolved" if locked.resolved? || locked.declined?
        raise Taken, "cannot challenge yourself" if locked.challenger_person_id == @opponent.id
        raise Taken, "duel taken" if locked.opponent_person_id.present? && locked.opponent_person_id != @opponent.id
        unless StakeScope.allowed?(challenger_ward: locked.challenger_ward || locked.ward, opponent_ward: @opponent.ward)
          raise Taken, "opponent outside stake"
        end

        if locked.opponent_person_id.nil?
          locked.update!(opponent_person: @opponent, opponent_ward: @opponent.ward)
        end

        existing = locked.opponent_run
        return Draw.frame(existing) if existing&.open? || existing&.finished?

        frame = StartPack.call(
          device_digest: @digest,
          person_id: @opponent.id,
          pack_id: locked.pack_id,
          challenge: true,
          street_duel: locked
        )
        locked.update!(opponent_run: frame.run)
        frame
      end
    end
  end
end
