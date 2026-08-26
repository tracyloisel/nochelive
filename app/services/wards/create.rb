module Wards
  class Create
    def self.call(**attrs)
      new(**attrs).call
    end

    def initialize(name:, emblem: "paloma", chapel_name: nil, chapel_address: nil, city: nil, region: nil, postal_code: nil, country_code: nil)
      @name = name.to_s.strip.first(Ward::NAME_MAX)
      @emblem = Team::EMBLEMS.key?(emblem.to_s) ? emblem.to_s : "paloma"
      @chapel_name = chapel_name.to_s.strip.first(80).presence
      @chapel_address = chapel_address.to_s.strip.first(80).presence
      @city = city.to_s.strip.first(80).presence
      @region = region.to_s.strip.first(80).presence
      @postal_code = postal_code.to_s.strip.first(80).presence
      @country_code = country_code.to_s.strip.upcase.presence
    end

    def call
      raise People::Error.new(:blank, I18n.t("errors.people.ward_blank")) if @name.blank?

      token = SecureRandom.urlsafe_base64(24)
      ward = nil
      8.times do
        ward = Ward.create!(
          name: @name,
          code: GameSession.generate_code,
          presenter_token_digest: GameSession.digest_token(token),
          emblem: @emblem,
          chapel_name: @chapel_name,
          chapel_address: @chapel_address,
          city: @city,
          region: @region,
          postal_code: @postal_code,
          country_code: @country_code,
          listed: !Ward.listed.exists?
        )
        ward.presenter_token = token
        break
      rescue ActiveRecord::RecordNotUnique
        ward = nil
      rescue ActiveRecord::RecordInvalid => error
        raise unless error.record.errors.of_kind?(:code, :taken)
        ward = nil
      end
      raise People::Error.new(:code, I18n.t("errors.people.ward_fail")) unless ward

      ward
    end
  end
end
