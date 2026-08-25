module Locales
  class Assign
    def self.call(night:, locale:, player: nil, person: nil)
      new(night:, locale:, player:, person:).call
    end

    def initialize(night:, locale:, player:, person:)
      @night = night
      @locale = Locale.cast(locale)
      @player = player
      @person = person || player&.person
    end

    def call
      raise People::Error.new(:missing, I18n.t("errors.people.missing")) if @player.nil? && @person.nil?

      if @player && @player.game_session_id != @night.id
        raise People::Error.new(:player, I18n.t("errors.people.player"))
      end
      if @person && @night.ward_id && @person.ward_id != @night.ward_id
        raise People::Error.new(:ward, I18n.t("errors.people.ward"))
      end

      target = @player || @night.players.find_by(person_id: @person.id)
      Locales::Set.call(locale: @locale, player: target, person: @person, night: @night, presenter: false)
    end
  end
end
