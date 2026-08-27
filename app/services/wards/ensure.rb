module Wards
  class Ensure
    def self.call(church_unit_id:)
      new(church_unit_id:).call
    end

    def initialize(church_unit_id:)
      @church_unit_id = church_unit_id.to_s.sub(/\AWARD:/i, "").strip
    end

    def call
      raise People::Error.new(:missing, I18n.t("errors.people.ward_missing")) if @church_unit_id.blank?

      attrs = QueryLocator.details(church_unit_id: @church_unit_id)
      SyncDirectory.call(rows: [ attrs ]) if attrs.present?

      Ward.find_by(church_unit_id: @church_unit_id) || raise(People::Error.new(:missing, I18n.t("errors.people.ward_missing")))
    end
  end
end
