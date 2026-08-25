module Locales
  class Set
    def self.call(locale:, player: nil, person: nil, night: nil, presenter: false)
      new(locale:, player:, person:, night:, presenter:).call
    end

    def initialize(locale:, player:, person:, night:, presenter:)
      @locale = Locale.cast(locale)
      @player = player
      @person = person || player&.person
      @night = night || player&.game_session
      @presenter = presenter
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
        @night.update!(presenter_locale: @locale) if @presenter && @night
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
