module Quizzes
  class ChallengeScreen
    Result = Struct.new(:duel, :role, :phase, :waiting_for, keyword_init: true)
    RECENT = 2.days
    PHASE_RANK = { accept: 0, play: 1, result: 2, waiting: 3 }.freeze

    def self.call(person: nil, token: nil, duel: nil)
      new(person:, token:, duel:).call
    end

    def initialize(person: nil, token: nil, duel: nil)
      @person = person
      @token = token.to_s.presence
      @duel = duel
    end

    def call
      if @duel || @token
        duel = @duel || duel_from_token
        return unless duel
        return if duel.expired? && !duel.resolved? && !duel.declined?

        return result_for(duel)
      end

      latest_for_person
    end

    private

      def duel_from_token
        return unless @token

        StreetDuel.find_by(token: @token)
      end

      def latest_for_person
        return unless @person

        StreetDuel
          .includes(:opponent_run)
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: @person.id)
          .where(status: %w[challenger_done opponent_done resolved])
          .where("expires_at > :now OR status = 'resolved'", now: Time.current)
          .where("status != 'resolved' OR updated_at > :recent", recent: RECENT.ago)
          .order(updated_at: :desc, id: :desc)
          .limit(24)
          .filter_map { |duel| result_for(duel) }
          .reject { |screen| screen.phase == :taken }
          .min_by { |screen| [ PHASE_RANK.fetch(screen.phase, 8), -screen.duel.updated_at.to_i, -screen.duel.id ] }
      end

      def result_for(duel)
        role = role_for(duel)
        phase = phase_for(duel, role)
        Result.new(duel:, role:, phase:, waiting_for: waiting_for(duel, role, phase))
      end

      def role_for(duel)
        return :guest unless @person
        return :challenger if duel.challenger_person_id == @person.id
        return :opponent if duel.opponent_person_id == @person.id
        return :invitee if duel.opponent_person_id.nil?

        :other
      end

      def phase_for(duel, role)
        return :taken if duel.declined?
        return :result if duel.resolved?
        return :taken if role == :other

        case role
        when :challenger
          :waiting
        when :opponent
          duel.opponent_run&.open? ? :play : (duel.opponent_run ? :waiting : :accept)
        else
          :accept
        end
      end

      def waiting_for(duel, role, phase)
        return unless phase == :waiting && role == :challenger
        return :link if duel.opponent_person_id.nil?
        return :play if duel.opponent_run&.open?

        :accept
      end
  end
end
