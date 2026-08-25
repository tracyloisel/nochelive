module Wards
  class Enter
    def self.call(code:)
      new(code:).call
    end

    def initialize(code:)
      @code = Ward.normalize_code(code)
    end

    def call
      ward = Ward.find_by(code: @code)
      raise People::Error.new(:missing, I18n.t("errors.people.ward_missing")) unless ward

      ward
    end
  end
end
