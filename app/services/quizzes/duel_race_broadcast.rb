module Quizzes
  class DuelRaceBroadcast
    TARGET = "duel_quiz_race".freeze

    def self.progress(run:, previous_score:)
      new(run:).progress(previous_score:)
    end

    def self.refresh(people:)
      people.compact.uniq(&:id).filter_map { |person| new.broadcast_for(person:) }
    end

    def self.result(duel:, viewer:)
      return unless duel&.resolved? && viewer && !duel.score_for(viewer).nil? && !duel.other_score_for(viewer).nil?

      mine = duel.score_for(viewer)
      theirs = duel.other_score_for(viewer)
      kind = if mine == theirs
        :official_tie
      elsif mine > theirs
        :official_ahead
      else
        :official_behind
      end
      new.broadcast_for(person: viewer, event: { duel_id: duel.id, kind: })
    end

    def self.crossing_kind(previous_score:, current_score:, viewer_score:)
      return :rival_progress if viewer_score.nil?
      return :rival_passed if previous_score <= viewer_score && current_score > viewer_score
      return :rival_tied if previous_score < viewer_score && current_score == viewer_score

      :rival_progress
    end

    def initialize(run: nil)
      @run = run
    end

    def progress(previous_score:)
      return [] unless @run&.open? && @run.person_id
      return [] if previous_score.nil? || @run.score <= previous_score

      eligible_duels.filter_map do |duel|
        viewer = duel.other_person_for(@run.person)
        next unless viewer

        viewer_run = current_run_for(viewer, duel:)
        viewer_score = duel.score_for(viewer)
        viewer_score = viewer_run&.score if viewer_score.nil?
        event = {
          duel_id: duel.id,
          kind: self.class.crossing_kind(previous_score:, current_score: @run.score, viewer_score:)
        }
        broadcast_for(person: viewer, run: viewer_run, event:)
      end
    rescue StandardError => error
      Rails.logger.warn("duel race broadcast failed: #{error.class}: #{error.message}")
      []
    end

    def broadcast_for(person:, run: nil, event: nil)
      run ||= current_run_for(person)
      campus = DuelCampus.call(person:, run:, race_event: event)
      I18n.with_locale(Locale.i18n(person.locale)) do
        Turbo::StreamsChannel.broadcast_replace_to(
          [ person, :duel_campus ],
          target: TARGET,
          partial: "home/duel_campus_rail",
          locals: { campus:, run: }
        )
      end
    rescue StandardError => error
      Rails.logger.warn("duel race refresh failed for person #{person.id}: #{error.class}: #{error.message}")
      nil
    end

    private

      def eligible_duels
        StreetDuel.active.not_expired
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: @run.person_id)
          .where("accepted_at <= ?", @run.opened_at)
          .includes(:challenger_person, :opponent_person)
      end

      def current_run_for(person, duel: nil)
        scope = QuizRun.open_runs.where(person:).order(id: :desc)
        scope = scope.where("opened_at >= ?", duel.accepted_at) if duel&.accepted_at
        scope.first
      end

  end
end
