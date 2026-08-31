module Locales
  class Set
    def self.call(locale:, player: nil, person: nil, night: nil)
      new(locale:, player:, person:, night:).call
    end

    def initialize(locale:, player:, person:, night:)
      @locale = Locale.cast(locale)
      @player = player
      @person = person || player&.person
      @night = night || player&.game_session
    end

    def call
      ApplicationRecord.transaction do
        @person&.update!(locale: @locale)
        @player&.update!(locale: @locale)
        if @person
          @person.players.joins(:game_session).merge(GameSession.live).find_each do |row|
            row.update!(locale: @locale)
          end
        end
      end

      broadcast_affected
      @locale
    end

    private

      def broadcast_affected
        sessions = []
        sessions << @night if @night
        Array(@person&.players).each { |row| sessions << row.game_session }
        sessions << @player&.game_session
        sessions.compact.uniq.each do |night|
          night.broadcast_state if night.live?
        end
      end
  end
end
