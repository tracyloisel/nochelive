module Freezes
  class Catch
    def self.call(round:, team:, player:)
      new(round:, team:, player:).call
    end

    def initialize(round:, team:, player:)
      @round = round
      @team = team
      @player = player
    end

    def call
      answer = persist_and_grade!
      @round.game_session.broadcast_state(pulse: { kind: "freeze", player: @player })
      answer
    end

    private

    def persist_and_grade!
      raise "Not a freeze" unless @round.definition.freeze?
      raise "Not yet" unless @round.locked?

      ApplicationRecord.transaction do
        locked = RoundRun.lock.find(@round.id)
        raise "Not yet" unless locked.locked?
        raise "Freeze has no mark" if locked.locked_at.blank?

        existing = Answer.find_by(round_run: locked, team: @team)
        return existing if existing

        ms = [ ((Time.current - locked.locked_at) * 1000).round, 0 ].max
        answer = Answer.create!(round_run: locked, team: @team, player: @player, body: ms.to_s)

        if ms <= locked.definition.freeze_window
          Scores::Apply.correct!(locked, @team, broadcast: false)
        else
          Scores::Apply.incorrect!(locked, @team, broadcast: false)
        end

        answer
      end
    end
  end
end
