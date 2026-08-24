module Wards
  class Create
    def self.call(name:)
      new(name:).call
    end

    def initialize(name:)
      @name = name.to_s.strip.first(48)
    end

    def call
      raise People::Error.new(:blank, "Escribe el nombre de la rama.") if @name.blank?

      token = SecureRandom.urlsafe_base64(24)
      ward = nil
      8.times do
        ward = Ward.create!(
          name: @name,
          code: GameSession.generate_code,
          presenter_token_digest: GameSession.digest_token(token)
        )
        ward.presenter_token = token
        break
      rescue ActiveRecord::RecordNotUnique
        ward = nil
      end
      raise People::Error.new(:code, "No se pudo crear la rama.") unless ward

      ward
    end
  end
end
