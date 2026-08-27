module Quizzes
  class EnsureHubDuel
    Result = Struct.new(:duel, :person, :rival, keyword_init: true)

    def self.call(person:, rival: nil, digest: nil)
      new(person:, rival:, digest:).call
    end

    def initialize(person:, rival: nil, digest: nil)
      @person = person
      @rival = rival
      @digest = digest.to_s.presence || GameSession.digest_token("hub-challenge-#{person.id}")
    end

    def call
      raise ArgumentError, "person required" unless @person&.ward

      rival = @rival || default_rival
      raise ArgumentError, "rival required" unless rival

      active_pair_scope(rival).includes(:challenger_run, :opponent_run).find_each { |row| finish_open_side!(row) }
      duel = pick_active_between(rival) || start_named!(rival)
      finish_open_side!(duel)
      Result.new(duel: duel.reload, person: @person, rival:)
    end

    private

      def default_rival
        scope = @person.ward.people.where.not(id: @person.id)
        scope.find_by(given_name_key: "pili") ||
          scope.find_by(given_name_key: "carmen", family_name_key: "garcia") ||
          scope.order(:id).first
      end

      def active_pair_scope(rival)
        StreetDuel
          .where(ward_id: @person.ward_id)
          .where("expires_at > ?", Time.current)
          .where(
            "(challenger_person_id = :a AND opponent_person_id = :b) OR (challenger_person_id = :b AND opponent_person_id = :a)",
            a: @person.id, b: rival.id
          )
          .where(status: %w[challenger_done opponent_done])
      end

      def pick_active_between(rival)
        active_pair_scope(rival).max_by { |duel| [ duel.updated_at.to_i, duel.id ] }
      end

      def start_named!(rival)
        run = usable_run_for(@person, rival) || play_pack!(@person, unused_pack_id(rival))
        ChallengeCreate.call(
          challenger_person: @person,
          ward: @person.ward,
          pack_id: run.pack_id,
          run:,
          opponent_person: rival
        ).duel
      end

      def usable_run_for(person, rival)
        QuizRun.finished.where(person_id: person.id).where.not(pack_id: resolved_pack_ids(rival)).order(:id).last
      end

      def unused_pack_id(rival)
        used = resolved_pack_ids(rival)
        QuizDefinition.catalog.pack_ids.find { |id| used.exclude?(id) } || "placas"
      end

      def resolved_pack_ids(rival)
        StreetDuel.where(status: "resolved").where(
          "(challenger_person_id = :a AND opponent_person_id = :b) OR (challenger_person_id = :b AND opponent_person_id = :a)",
          a: @person.id, b: rival.id
        ).pluck(:pack_id)
      end

      def finish_open_side!(duel)
        run = [ duel.opponent_run, duel.challenger_run ].compact.find(&:open?)
        play_through!(run) if run
      end

      def play_pack!(person, pack_id)
        frame = StartPack.call(
          device_digest: GameSession.digest_token("#{@digest}-#{person.id}-#{pack_id}"),
          pack_id:,
          person_id: person.id,
          challenge: true
        )
        play_through!(frame.run)
      end

      def play_through!(run)
        return run if run.finished?

        loop do
          run.reload
          break if run.finished?

          keep_clock!(run)
          Submit.call(run:, choice_key: run.question.correct_choice)
          run.reload
          if run.last_question? && run.settled?
            Complete.call(run:)
            break
          end
          Advance.call(run:)
        end
        run.reload
      end

      def keep_clock!(run)
        return if run.ends_at.blank? || run.ends_at > Time.current

        run.update!(ends_at: 20.minutes.from_now, asked_at: Time.current)
      end
  end
end
