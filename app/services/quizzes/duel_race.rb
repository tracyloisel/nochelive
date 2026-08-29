module Quizzes
  class DuelRace
    Snapshot = Struct.new(
      :item, :kind, :mine, :theirs, :gap, :crowns_needed, :provisional, :official,
      :event, keyword_init: true
    )

    EVENT_KINDS = %i[
      you_passed you_tied rival_passed rival_tied rival_progress
      official_ahead official_behind official_tie
    ].freeze
    OFFICIAL_EVENT_KINDS = %i[official_ahead official_behind official_tie].freeze
    COMPARISON_KINDS = %i[ahead tied chasing].freeze

    def self.call(person:, active:, run: nil, previous_score: nil, event: nil)
      new(person:, active:, run:, previous_score:, event:).call
    end

    def initialize(person:, active:, run:, previous_score:, event:)
      @person = person
      @active = active
      @run = run
      @previous_score = previous_score
      @event = event&.symbolize_keys
    end

    def call
      return if @active.empty?

      snapshots = @active.map { |item| snapshot_for(item) }
      snapshots.min_by { |snapshot| priority_for(snapshot) }
    end

    private

      def snapshot_for(item)
        mine, mine_provisional = projected_mine(item)
        theirs, theirs_provisional = projected_theirs(item)
        event_kind = event_kind_for(item, mine, theirs)
        kind = event_kind || steady_kind_for(item, mine, theirs)
        gap = mine.nil? || theirs.nil? ? nil : mine - theirs

        Snapshot.new(
          item:,
          kind:,
          mine:,
          theirs:,
          gap:,
          crowns_needed: gap&.negative? ? gap.abs + 1 : nil,
          provisional: mine_provisional || theirs_provisional,
          official: OFFICIAL_EVENT_KINDS.include?(kind) ||
            (!mine.nil? && !theirs.nil? && !mine_provisional && !theirs_provisional),
          event: EVENT_KINDS.include?(kind)
        )
      end

      def projected_mine(item)
        return [ item.mine, false ] unless item.mine.nil?
        return [ nil, false ] unless eligible_run?(@run, item) && @run.person_id == @person.id

        [ @run.score, @run.open? ]
      end

      def projected_theirs(item)
        return [ item.theirs, false ] unless item.theirs.nil?
        return [ nil, false ] unless eligible_run?(item.rival_run, item) && item.rival_run.person_id == item.other&.id

        [ item.rival_run.score, item.rival_run.open? ]
      end

      def eligible_run?(run, item)
        run && run.opened_at && item.duel.accepted_at && run.opened_at >= item.duel.accepted_at
      end

      def event_kind_for(item, mine, theirs)
        if @event && @event[:duel_id].to_i == item.duel.id
          kind = @event[:kind]&.to_sym
          return kind if EVENT_KINDS.include?(kind)
        end

        local_crossing_kind(item, mine, theirs)
      end

      def local_crossing_kind(item, mine, theirs)
        return unless eligible_run?(@run, item)
        return if @previous_score.nil? || mine.nil? || theirs.nil? || mine <= @previous_score
        return :you_passed if @previous_score <= theirs && mine > theirs
        return :you_tied if @previous_score < theirs && mine == theirs
      end

      def steady_kind_for(item, mine, theirs)
        if !mine.nil? && !theirs.nil?
          return :ahead if mine > theirs
          return :tied if mine == theirs

          :chasing
        elsif !theirs.nil?
          :target
        elsif !mine.nil?
          :waiting
        elsif item.rival_live
          :rival_live
        elsif item.rematch
          :rematch_ready
        else
          :ready
        end
      end

      def priority_for(snapshot)
        kind_rank = if snapshot.event
          0
        elsif COMPARISON_KINDS.include?(snapshot.kind)
          1
        elsif snapshot.kind == :target
          2
        elsif snapshot.kind == :rival_live
          3
        elsif snapshot.kind == :waiting
          4
        elsif snapshot.kind == :rematch_ready
          5
        else
          6
        end
        closeness = snapshot.gap.nil? ? 10_000 : snapshot.gap.abs

        [ kind_rank, closeness, snapshot.item.duel.id ]
      end
  end
end
