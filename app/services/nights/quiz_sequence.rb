module Nights
  class QuizSequence
    def self.current_or_start(night:, player:, device_digest:)
      new(night:, player:, device_digest:).current_or_start
    end

    def self.next_after(run:)
      new(night: run.game_session, player: run.player, device_digest: run.device_digest).next_after(run)
    end

    def initialize(night:, player:, device_digest:)
      @night = night
      @player = player
      @device_digest = device_digest
    end

    def current_or_start
      ensure_playable!
      ensure_team!
      @player.quiz_runs.live.open_runs.order(:live_sequence_position).last ||
        @player.quiz_runs.live.order(:live_sequence_position).last ||
        create_run(1)
    end

    def next_after(run)
      ensure_playable!
      raise "Finish this quiz first" unless run.finished?

      position = run.live_sequence_position + 1
      return nil if position > @night.quiz_pack_ids.size

      @player.quiz_runs.find_by(game_session: @night, live_sequence_position: position) || create_run(position)
    end

    private

      def ensure_playable!
        @night.reconcile!
        raise "Noche Live is not open for play" unless @night.playable?
      end

      def ensure_team!
        raise "Choose a team first" unless @player.team
      end

      def create_run(sequence_position)
        pack_id = @night.quiz_pack_ids.fetch(sequence_position - 1)
        pack = QuizDefinition.catalog.find_pack(pack_id)
        question = pack.question_at(1)
        QuizRun.create!(
          device_digest: @device_digest,
          person: @player.person,
          game_session: @night,
          player: @player,
          team: @player.team,
          live_sequence_position: sequence_position,
          pack_id:,
          position: 1,
          score: 0,
          status: "open",
          opened_at: Time.current,
          **Quizzes::AskClock.opening_attrs(question)
        ).tap do |run|
          Nights::Events.emit(
            night: @night,
            kind: "quiz_start",
            dedupe_key: "quiz-start:#{run.id}",
            payload: { player_id: @player.id, team_id: @player.team.id, pack_id:, sequence_position: }
          )
        end
      rescue ActiveRecord::RecordNotUnique
        @player.quiz_runs.find_by!(game_session: @night, live_sequence_position: sequence_position)
      end
  end
end
