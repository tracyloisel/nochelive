module Scriptures
  class RecordRead
    Result = Data.define(:counted, :reads_count)

    def self.call(reference:, reader_digest:, locale:, person: nil, at: Time.current)
      new(reference:, reader_digest:, locale:, person:, at:).call
    end

    def initialize(reference:, reader_digest:, locale:, person:, at:)
      @reference = reference.to_s
      @reader_digest = reader_digest.to_s
      @locale = Locale.cast(locale)
      @person = person
      @at = at
    end

    def call
      raise ArgumentError, "unknown scripture reference" unless Quizzes::Scripture.known_study?(@reference)
      raise ArgumentError, "reader required" if @reader_digest.blank?

      counted = false
      count = ScriptureChapterRead.transaction do
        reading = ScriptureChapterRead.create_or_find_by!(
          reference: @reference,
          reader_digest: @reader_digest,
          read_on: @at.to_date
        ) do |record|
          record.person = @person
          record.locale = @locale
        end

        counted = reading.previously_new_record?
        stat = ScriptureChapterStat.create_or_find_by!(reference: @reference)
        if counted
          ScriptureChapterStat.where(id: stat.id).update_all(
            [ "reads_count = reads_count + 1, last_read_at = ?, updated_at = ?", @at, @at ]
          )
          stat.reload
        end
        stat.reads_count
      end

      Result.new(counted:, reads_count: count)
    end
  end
end
