module Wards
  class Enter
    def self.call(code: nil, church_unit_id: nil)
      new(code:, church_unit_id:).call
    end

    def initialize(code: nil, church_unit_id: nil)
      @code = Ward.normalize_code(code)
      @church_unit_id = church_unit_id.to_s.strip.presence
    end

    def call
      return Ensure.call(church_unit_id: @church_unit_id) if @church_unit_id.present? && @code.blank?

      ward = Ward.find_by(code: @code)
      raise People::Error.new(:missing, I18n.t("errors.people.ward_missing")) unless ward

      ward
    end
  end
end
