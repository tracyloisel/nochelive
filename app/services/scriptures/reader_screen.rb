module Scriptures
  class ReaderScreen
    Result = Data.define(
      :preference, :progress, :marks, :guide, :movement, :circle_mode, :circle_thread,
      :circle_posts, :video_links, :chapter_history
    )

    def self.call(person:, reference:, locale:)
      new(person:, reference:, locale:).call
    end

    def initialize(person:, reference:, locale:)
      @person = person
      @reference = reference
      @locale = Locale.cast(locale)
    end

    def call
      preference = @person&.scripture_reader_preference || ScriptureReaderPreference.new
      progress = @person&.scripture_reading_progresses&.find_by(reference: @reference, locale: @locale)
      marks = @person ? @person.scripture_marks.includes(:scripture_tags, :scripture_notebooks, :scripture_mark_links).for_reader(reference: @reference, locale: @locale).to_a : []
      guide = ScriptureChapterGuide.published.find_by(reference: @reference, locale: @locale)
      movement = Scriptures::WardMovement.call(person: @person, reference: @reference)
      circle_mode = @person&.ward&.scripture_circle_mode || "disabled"
      thread, posts = circle_preview(circle_mode)
      videos = ScriptureVideoLink.published.where(reference: @reference, locale: @locale).limit(3).to_a
      chapter_history = Scriptures::ChapterHistory.call(
        person: @person, reference: @reference, locale: @locale, marks:, progress:
      )

      Result.new(
        preference:, progress:, marks:, guide:, movement:, circle_mode:,
        circle_thread: thread, circle_posts: posts, video_links: videos, chapter_history:
      )
    end

    private

      def circle_preview(mode)
        return [ nil, [] ] unless @person&.ward_id && mode.in?(%w[read_only active])
        thread = ScriptureCircleThread.find_by(ward_id: @person.ward_id, reference: @reference)
        return [ nil, [] ] unless thread
        posts = thread.scripture_circle_posts
          .includes(:person, :parent, scripture_circle_moderation_proposals: [ :proposer_person, :scripture_circle_moderation_ballots ])
          .order(created_at: :desc, id: :desc).limit(20).to_a.reverse
        [ thread, posts ]
      end
  end
end
