module People
  class Transfer
    def self.call(person:, ward:)
      new(person:, ward:).call
    end

    def initialize(person:, ward:)
      @person = person
      @ward = ward
    end

    def call
      raise Error.new(:ward, I18n.t("errors.people.ward_missing")) unless @ward
      raise Error.new(:missing, I18n.t("errors.people.missing")) unless @person

      ApplicationRecord.transaction do
        @person.lock!
        return @person if @person.ward_id == @ward.id

        @person.update!(ward: @ward, last_ward_team: nil)
        @person
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      raise Error.new(:taken, I18n.t("errors.people.ward_taken"))
    end
  end
end
