module Quizzes
  class DuelCampus
    InvitationItem = Struct.new(
      :invitation, :direction, :state, :other, :score, :action, :receipt_state, :token,
      keyword_init: true
    )
    DuelItem = Struct.new(
      :duel, :other, :mine, :theirs, :outcome, :state, :action, :unseen, :rematch,
      :mine_run, :theirs_run, :rival_run, :rival_live,
      keyword_init: true
    )
    Counts = Struct.new(
      :active, :incoming, :waiting, :results, :ahead, :behind, :ties,
      keyword_init: true
    )
    Result = Struct.new(
      :incoming, :outgoing, :active, :results, :focus, :impacts, :counts,
      :next_desire, :friends, :race, keyword_init: true
    ) do
      def any? = counts.active.positive? || counts.incoming.positive? || counts.results.positive?
      def engaged_count = active.count { |item| item.duel.accepted_at.present? }
    end

    def self.call(person:, run: nil, at: Time.current, previous_score: nil, race_event: nil)
      new(person:, run:, at:, previous_score:, race_event:).call
    end

    def initialize(person:, run:, at:, previous_score:, race_event:)
      @person = person
      @run = run
      @at = at
      @previous_score = previous_score
      @race_event = race_event
    end

    def call
      return empty_result unless @person

      invitations = invitation_rows
      duels = duel_rows
      active = duels.select { |item| item.duel.active? && !item.duel.expired? }
      results = duels.select { |item| item.duel.resolved? }.sort_by { |item| [ item.unseen ? 0 : 1, -item.duel.resolved_at.to_i ] }
      incoming = invitations.select { |item| item.direction == :incoming && item.state == :available }
      outgoing = invitations.select { |item| item.direction == :outgoing }
      impacts = @run ? duels.select { |item| item.duel.challenger_run_id == @run.id || item.duel.opponent_run_id == @run.id } : []
      race_pool = active
      if @race_event
        event_duel_id = @race_event.to_h.symbolize_keys[:duel_id].to_i
        event_item = duels.find { |item| item.duel.id == event_duel_id }
        race_pool = [ *active, event_item ].compact.uniq { |item| item.duel.id }
      end
      race = DuelRace.call(
        person: @person,
        active: race_pool,
        run: @run,
        previous_score: @previous_score,
        event: @race_event
      )
      Result.new(
        incoming:,
        outgoing:,
        active: active.sort_by { |item| active_rank(item) },
        results:,
        focus: race&.item,
        impacts: impacts.sort_by { |item| result_rank(item) },
        counts: counts_for(active, incoming, results),
        next_desire: next_desire_for(impacts, results),
        friends: active.map(&:other).compact.uniq(&:id).first(3),
        race:
      )
    end

    private

      def invitation_rows
        DuelInvitation
          .where("challenger_person_id = :id OR recipient_person_id = :id", id: @person.id)
          .where.not(status: %w[revoked expired])
          .includes(:challenger_person, :recipient_person, :claimed_by_person, :challenger_run, :street_duel)
          .order(updated_at: :desc, id: :desc)
          .limit(40)
          .map { |invitation| invitation_item(invitation) }
      end

      def invitation_item(invitation)
        direction = invitation.challenger_person_id == @person.id ? :outgoing : :incoming
        other = if direction == :outgoing
          invitation.recipient_person || invitation.claimed_by_person
        else
          invitation.challenger_person
        end
        state = if invitation.expired?
          :expired
        elsif invitation.claimed?
          :claimed
        elsif invitation.declined?
          :declined
        else
          :available
        end
        action = if direction == :incoming && state == :available
          :accept
        elsif direction == :outgoing && state == :available
          invitation.external? ? :share : :wait
        elsif state == :claimed
          :open_duel
        end
        InvitationItem.new(
          invitation:,
          direction:,
          state:,
          other:,
          score: invitation.challenger_score,
          action:,
          receipt_state: invitation.receipt_state,
          token: invitation.public_token
        )
      end

      def duel_rows
        duels = StreetDuel
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: @person.id)
          .where.not(status: "archived")
          .includes(:challenger_person, :opponent_person, :challenger_run, :opponent_run, :origin_invitation)
          .order(updated_at: :desc, id: :desc)
          .limit(60)
          .to_a
        opponent_ids = duels.filter_map { |duel| duel.other_person_for(@person)&.id }.uniq
        @live_opponent_ids = Presences::Registry.online_person_ids(among: opponent_ids)
        @open_runs_by_person_id = QuizRun.street.open_runs
          .where(person_id: opponent_ids)
          .order(id: :desc)
          .each_with_object({}) { |run, rows| rows[run.person_id] ||= run }
        duels.map { |duel| duel_item(duel) }
      end

      def duel_item(duel)
        mine = duel.score_for(@person)
        theirs = duel.other_score_for(@person)
        other = duel.other_person_for(@person)
        rival_run = @open_runs_by_person_id[other&.id]
        rival_run = nil if rival_run && rival_run.opened_at < duel.accepted_at
        outcome = outcome_for(mine, theirs)
        state = if duel.resolved?
          :resolved
        elsif mine.nil? && theirs.present?
          :your_turn
        elsif mine.present? && theirs.nil?
          :waiting
        else
          :ready
        end
        action = case state
        when :your_turn, :ready then :play
        when :resolved then :view
        end
        DuelItem.new(
          duel:,
          other:,
          mine:,
          theirs:,
          outcome:,
          state:,
          action:,
          unseen: duel.resolved? && duel.result_seen_at_for(@person).nil?,
          rematch: duel.rematch?,
          mine_run: duel.run_for(@person),
          theirs_run: duel.run_for(other),
          rival_run:,
          rival_live: @live_opponent_ids.include?(other&.id)
        )
      end

      def outcome_for(mine, theirs)
        return :waiting if theirs.nil?
        return :your_turn if mine.nil?
        return :tie if mine == theirs

        mine > theirs ? :ahead : :behind
      end

      def active_rank(item)
        rank = { your_turn: 0, ready: 1, waiting: 2 }.fetch(item.state, 9)
        [ rank, item.rematch ? 0 : 1, -item.duel.updated_at.to_i, -item.duel.id ]
      end

      def result_rank(item)
        rank = { tie: 0, ahead: 1, behind: 2, waiting: 3 }.fetch(item.outcome, 9)
        [ item.rematch ? 0 : 1, rank, (item.mine.to_i - item.theirs.to_i).abs, -item.duel.id ]
      end

      def counts_for(active, incoming, results)
        Counts.new(
          active: active.size,
          incoming: incoming.size,
          waiting: active.count { |item| item.state == :waiting },
          results: results.count(&:unseen),
          ahead: results.count { |item| item.outcome == :ahead },
          behind: results.count { |item| item.outcome == :behind },
          ties: results.count { |item| item.outcome == :tie }
        )
      end

      def next_desire_for(impacts, results)
        acquired = DuelInvitation.where(status: "claimed", claimed_by_person: @person).exists?
        return :propagate if acquired && (@run&.finished? || impacts.any?)
        return :rematch if impacts.any? || results.any?

        :play
      end

      def empty_result
        Result.new(
          incoming: [], outgoing: [], active: [], results: [], focus: nil, impacts: [], friends: [],
          counts: Counts.new(active: 0, incoming: 0, waiting: 0, results: 0, ahead: 0, behind: 0, ties: 0),
          next_desire: :play, race: nil
        )
      end
  end
end
