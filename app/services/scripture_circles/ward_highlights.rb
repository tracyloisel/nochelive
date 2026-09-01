module ScriptureCircles
  # A compact, visibility-safe projection of this ward's recent weekly
  # conversations. The ward page stays public, but this projection only
  # returns data when the viewer belongs to the requested ward.
  class WardHighlights
    LIMIT = 2
    WINDOW_DAYS = 7

    Highlight = LibraryHighlights::Highlight

    def self.call(ward:, person:, locale:, references:, at: Time.current)
      return [] unless ward && person&.ward_id == ward.id

      new(ward:, person:, locale:, references:, at:).call
    end

    def initialize(ward:, person:, locale:, references:, at:)
      @ward = ward
      @person = person
      @locale = Locale.i18n(locale)
      @references = Array(references).map(&:to_s).select(&:present?).uniq
      @at = at
      @routes = Rails.application.routes.url_helpers
    end

    def call
      return [] if @references.empty?

      access = Access.new(person: @person).readable!
      return [] unless access.ward.id == @ward.id

      zone = ActiveSupport::TimeZone[@ward.time_zone] || Time.zone
      local_now = @at.in_time_zone(zone)
      activity_window = (local_now.beginning_of_day - (WINDOW_DAYS - 1).days)..local_now.end_of_day
      feed = ConversationFeed.new(ward: @ward, references: @references)
      roots = feed
        .ordered(feed.roots, sort: "recent")
        .where("circle_stats.last_activity_at BETWEEN ? AND ?", activity_window.begin, activity_window.end)
        .includes(:person)
        .limit(LIMIT)
        .to_a

      roots.filter_map { |root| highlight_for(root) }.freeze
    rescue Access::MissingIdentity, Access::MissingWard, Access::Disabled
      []
    end

    private

      def highlight_for(root)
        study = root.read_attribute("circle_reference").to_s
        reference = Scriptures::Reference.from_study(study:, locale: @locale, verse: 1)
        return unless reference

        author = SafeAuthor.call(post: root, viewer: @person, ward: @ward, locale: @locale)
        citation = "#{reference.book_label} #{reference.chapter}"
        Highlight.new(
          id: root.id,
          kind: root.kind,
          body: root.body,
          selected_text: root.selected_text,
          created_at: root.created_at,
          author_name: author.name,
          avatar_key: author.avatar_key,
          anonymous: author.anonymous,
          own: author.own,
          reference: study,
          citation:,
          reply_count: root.read_attribute("circle_reply_count").to_i,
          path: @routes.scripture_circle_path(locale: @locale, conversation: root.id),
          reader_path: @routes.scripture_path(study, cite: citation, locale: @locale)
        )
      end
  end
end
