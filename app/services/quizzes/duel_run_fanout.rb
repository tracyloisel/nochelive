module Quizzes
  class DuelRunFanout
    Impact = Struct.new(:duel, :other, :outcome, :mine, :theirs, :newly_resolved, keyword_init: true)

    def self.call(run:)
      new(run:).call
    end

    def initialize(run:)
      @run = run
    end

    def call
      return [] unless @run&.finished? && @run.person_id

      resolved_ids = []
      impacts = ApplicationRecord.transaction do
        run = QuizRun.lock.find(@run.id)
        eligible_duels(run).lock("FOR UPDATE").order(:id).filter_map do |duel|
          impact = commit_run(duel, run)
          resolved_ids << duel.id if impact&.newly_resolved
          impact
        end
      end
      after_commit(impacts, resolved_ids)
      impacts
    end

    private

      def eligible_duels(run)
        StreetDuel.active.not_expired
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: run.person_id)
          .where("accepted_at <= ?", run.opened_at)
      end

      def commit_run(duel, run)
        role = duel.role_for(run.person)
        return if role == :other
        run_column = role == :challenger ? :challenger_run : :opponent_run
        score_column = role == :challenger ? :challenger_score : :opponent_score
        return if duel.public_send("#{run_column}_id").present?

        attrs = { run_column => run, score_column => run.score }
        other_score = role == :challenger ? duel.opponent_score : duel.challenger_score
        newly_resolved = other_score.present?
        if newly_resolved
          attrs.merge!(
            status: "resolved",
            resolved_at: Time.current
          )
        else
          attrs[:status] = "one_scored"
        end
        duel.update!(attrs)
        Impact.new(
          duel:,
          other: duel.other_person_for(run.person),
          outcome: outcome_for(duel, run.person),
          mine: run.score,
          theirs: other_score,
          newly_resolved:
        )
      end

      def outcome_for(duel, person)
        mine = duel.score_for(person)
        theirs = duel.other_score_for(person)
        return :waiting if theirs.nil?
        return :tie if mine == theirs

        mine > theirs ? :ahead : :behind
      end

      def after_commit(impacts, resolved_ids)
        impacts.each do |impact|
          ViralTrack.call(
            name: "duel_run_committed",
            device_digest: @run.device_digest,
            duel: impact.duel,
            person: @run.person,
            source: "run",
            event_key: "duel-run-committed:#{impact.duel.id}:#{@run.id}",
            properties: { outcome: impact.outcome, pack_id: @run.pack_id }
          )
        end
        resolved_ids.each do |id|
          duel = StreetDuel.find(id)
          ViralTrack.call(
            name: "duel_resolved",
            device_digest: @run.device_digest,
            duel:,
            person: @run.person,
            source: "run",
            event_key: "duel-resolved:#{duel.id}",
            properties: { outcome: outcome_for(duel, @run.person) }
          )
          Notifications::DuelResults.call(duel:)
        end
        return if impacts.empty?

        ViralTrack.call(
          name: "multi_duel_run_completed",
          device_digest: @run.device_digest,
          person: @run.person,
          source: "run",
          event_key: "multi-duel-run-completed:#{@run.id}",
          properties: { count: impacts.size, resolved_count: resolved_ids.size, pack_id: @run.pack_id }
        )
        impacts.each do |impact|
          if impact.newly_resolved
            DuelRaceBroadcast.result(duel: impact.duel, viewer: impact.other)
          else
            DuelRaceBroadcast.refresh(people: [ impact.other ])
          end
        end
      end
  end
end
