module ScriptureCircles
  # A compact, visibility-safe projection of today's thoughts for the Library.
  # It returns at most two roots and never hands Active Record objects to the
  # view, keeping the Library an editorial stream rather than a second inbox.
  class LibraryHighlights
    LIMIT = 2

    Highlight = Data.define(
      :id,
      :kind,
      :body,
      :selected_text,
      :created_at,
      :author_name,
      :avatar_key,
      :anonymous,
      :own,
      :reference,
      :citation,
      :reply_count,
      :path,
      :reader_path
    ) do
      def anonymous? = anonymous
      def own? = own
    end

    def self.call(person:, locale:, references:, at: Time.current)
      return [] unless person

      new(person:, locale:, references:, at:).call
    end

    def initialize(person:, locale:, references:, at:)
      @person = person
      @locale = Locale.i18n(locale)
      @references = Array(references).map(&:to_s).select(&:present?).uniq
      @at = at
      @routes = Rails.application.routes.url_helpers
    end

    def call
      return [] if @references.empty?

      access = Access.new(person: @person).readable!
      ward = access.ward
      zone = ActiveSupport::TimeZone[ward.time_zone] || Time.zone
      day = @at.in_time_zone(zone)
      feed = ConversationFeed.new(ward:, references: @references)
      roots = feed
        .ordered(feed.roots, sort: "recent")
        .where(scripture_circle_posts: { created_at: day.beginning_of_day..day.end_of_day })
        .includes(:person)
        .limit(LIMIT)
        .to_a

      roots.filter_map { |root| highlight_for(root, ward:) }.freeze
    rescue Access::MissingIdentity, Access::MissingWard, Access::Disabled
      []
    end

    private

      def highlight_for(root, ward:)
        study = root.read_attribute("circle_reference").to_s
        reference = Scriptures::Reference.from_study(study:, locale: @locale, verse: 1)
        return unless reference

        author = SafeAuthor.call(post: root, viewer: @person, ward:, locale: @locale)
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
