module Wards
  class Open
    def self.call(code:, token:)
      new(code:, token:).call
    end

    def initialize(code:, token:)
      @code = Ward.normalize_code(code)
      @token = token.to_s
    end

    def call
      ward = Ward.find_by(code: @code)
      raise People::Error.new(:missing, "Esa rama no existe.") unless ward
      raise People::Error.new(:token, "Ese enlace no es válido.") unless ward.presenter_token_matches?(@token)

      ward
    end
  end
end
