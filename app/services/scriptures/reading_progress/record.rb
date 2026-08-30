module Scriptures
  module ReadingProgress
    class Record
      def self.call(person:, reference:, locale:, last_verse:, progress_ratio:, last_offset: nil, completed: false, at: Time.current)
        new(person:, reference:, locale:, last_verse:, progress_ratio:, last_offset:, completed:, at:).call
      end

      def initialize(person:, reference:, locale:, last_verse:, progress_ratio:, last_offset:, completed:, at:)
        @person = person
        @reference = reference.to_s
        @locale = Locale.cast(locale)
        @last_verse = last_verse.to_i
        @ratio = progress_ratio.to_f.clamp(0, 1)
        @last_offset = last_offset.presence&.to_i
        @completed = ActiveModel::Type::Boolean.new.cast(completed)
        @at = at
      end

      def call
        progress = @person.scripture_reading_progresses.find_or_initialize_by(reference: @reference, locale: @locale)
        progress.first_opened_at ||= @at
        progress.last_opened_at = @at
        if progress.new_record? || @ratio >= progress.progress_ratio.to_f
          progress.last_verse = @last_verse
          progress.last_offset = @last_offset
          progress.progress_ratio = @ratio
        end
        progress.completed_at ||= @at if @completed || @ratio >= 0.98
        progress.save!
        progress
      end
    end
  end
end
