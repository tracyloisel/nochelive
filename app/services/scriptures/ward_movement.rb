module Scriptures
  class WardMovement
    PRIVACY_THRESHOLD = 5
    WINDOW = 7.days

    Result = Data.define(:count, :exact, :visible) do
      def exact? = exact
      def visible? = visible
    end

    def self.call(person:, reference:, at: Time.current)
      return Result.new(count: 0, exact: false, visible: false) unless person&.ward_id

      count = ScriptureChapterRead.where(
        ward_id: person.ward_id,
        reference:,
        created_at: (at - WINDOW)..at
      ).where.not(person_id: nil).distinct.count(:person_id)
      Result.new(count:, exact: count >= PRIVACY_THRESHOLD, visible: count.positive?)
    end
  end
end
