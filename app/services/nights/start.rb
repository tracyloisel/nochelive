module Nights
  class Start
    def self.call(ward:, quiz_ids:, starts_at: Time.current)
      new(ward:, quiz_ids:, starts_at:).call
    end

    def initialize(ward:, quiz_ids:, starts_at:)
      @ward = ward
      @quiz_ids = normalize_quiz_ids(quiz_ids)
      @starts_at = starts_at.in_time_zone
    end

    def call
      night = allocate_night
      raise "Could not allocate a session code" unless night

      @ward.ward_teams.find_each do |ward_team|
        night.teams.create!(name: ward_team.name, emblem: ward_team.emblem, ward_team:)
      end
      Nights::ScheduleLifecycle.call(night:)
      night
    end

    private

      def normalize_quiz_ids(quiz_ids)
        ids = Array(quiz_ids).map { |id| id.to_s.strip }.reject(&:blank?)
        raise ArgumentError, "quiz_ids must contain at least one quiz" if ids.empty?
        raise ArgumentError, "quiz_ids cannot contain duplicates" if ids.uniq.size != ids.size

        ids.each { |id| QuizDefinition.catalog.find_pack(id) }
        ids
      rescue QuizDefinition::Error => error
        raise ArgumentError, error.message
      end

      def allocate_night
        8.times do
          return GameSession.create!(
            ward: @ward,
            code: GameSession.generate_code,
            status: "scheduled",
            quiz_pack_ids: @quiz_ids,
            starts_at: @starts_at,
            ends_at: @starts_at + GameSession::DURATION
          )
        rescue ActiveRecord::RecordNotUnique
          next
        end
        nil
      end
  end
end
