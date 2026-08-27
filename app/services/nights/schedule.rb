module Nights
  class Schedule
    def self.call(ward:, starts_at:, theme_id: "reyes_y_profetas", missionary_names: [])
      new(ward:, starts_at:, theme_id:, missionary_names:).call
    end

    def initialize(ward:, starts_at:, theme_id:, missionary_names:)
      @ward = ward
      @starts_at = starts_at
      @theme_id = theme_id
      @missionary_names = Array(missionary_names).map { |name| name.to_s.strip.first(32) }.reject(&:blank?)
    end

    def call
      definition = GameDefinition.load(@theme_id)
      night = existing_lobby || Nights::Start.call(ward: @ward, theme_id: @theme_id)
      night.update!(
        starts_at: @starts_at,
        theme_id: definition.theme.id,
        theme_title: definition.theme.title
      )
      @missionary_names.each do |name|
        next if night.missionaries.exists?(name:)

        Missionaries::Add.call(night:, name:)
      end
      night.reload
    end

    private

      def existing_lobby
        @ward.game_sessions.where(status: "lobby")
          .where(starts_at: @starts_at.beginning_of_day..)
          .order(:starts_at, :id)
          .first
      end
  end
end
