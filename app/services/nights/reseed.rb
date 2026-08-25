module Nights
  class Reseed
    WIPE = [
      Cheer, Ballot, Buzz, Answer, TapRun, PoseHold, ScoreEvent, RewardGrant,
      TeamMembership, PresenterClaim, PresenterBlock, QuizAnswer, QuizRun,
      Missionary, RoundRun, Player, Team, GameSession
    ].freeze

    def self.call
      new.call
    end

    def call
      ApplicationRecord.transaction do
        ApplicationRecord.connection.disable_referential_integrity do
          WIPE.each(&:delete_all)
        end
      end

      load Rails.root.join("db/seeds.rb")
      GameSession.find_by_code("DEMO")
    end
  end
end
