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
      raise People::Error.new(:missing, I18n.t("errors.people.ward_missing")) unless ward
      raise People::Error.new(:token, I18n.t("errors.people.token")) unless ward.presenter_token_matches?(@token)

      ward
    end
  end
end
