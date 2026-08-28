module Quizzes
  class ChallengeDecline
    class Expired < StandardError; end
    class Taken < StandardError; end

    def self.call(duel:, opponent_person:)
      new(duel:, opponent_person:).call
    end

    def initialize(duel:, opponent_person:)
      @duel = duel
      @opponent = opponent_person
    end

    def call
      raise Expired, "duel expired" if @duel.expired?
      raise Taken, "duel resolved" if @duel.resolved? || @duel.declined? || @duel.archived?

      ApplicationRecord.transaction do
        locked = StreetDuel.lock.find(@duel.id)
        raise Expired, "duel expired" if locked.expired?
        raise Taken, "duel resolved" if locked.resolved? || locked.declined? || locked.archived?
        raise Taken, "cannot decline your own challenge" if locked.challenger_person_id == @opponent.id
        raise Taken, "duel taken" if locked.opponent_person_id != @opponent.id

        locked.update!(status: "declined")
        locked
      end
    end
  end
end
