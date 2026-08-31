module Hubs
  # The Hub may invite a signed-in member into the Circle, but it never turns
  # a member post into promotional copy. The card exposes only aggregate,
  # ward-scoped activity so the Hub can feel alive without publishing a
  # reflection or an author's identity outside the Circle.
  class CircleDiscovery
    Activity = Struct.new(:threads, :replies, :last_at, keyword_init: true) do
      def present? = threads.positive? || replies.positive?
    end
    Card = Struct.new(:state, :path, :artwork, :activity, keyword_init: true)

    def self.call(person:, ward:, theme:)
      new(person:, ward:, theme:).call
    end

    def initialize(person:, ward:, theme:)
      @person = person
      @ward = ward
      @theme = theme.to_s
      @routes = Rails.application.routes.url_helpers
    end

    def call
      return unless @person && @ward
      return unless @person.ward_id == @ward.id
      return unless @ward.scripture_circle_readable?

      mode = %w[light dark].include?(@theme) ? @theme : "dark"
      Card.new(
        state: @ward.scripture_circle_mode.to_sym,
        path: @routes.scripture_circle_path,
        artwork: "scripture_circle.backdrop.#{mode}",
        activity: activity
      )
    end

    private

      def activity
        posts = @ward.scripture_circle_posts
          .joins(:scripture_circle_thread)
          .visible
          .where(scripture_circle_threads: { status: "active" })
          .where(created_at: 7.days.ago..)

        total, threads, last_at = posts.pick(
          Arel.sql("COUNT(*)"),
          Arel.sql("SUM(CASE WHEN scripture_circle_posts.parent_id IS NULL THEN 1 ELSE 0 END)"),
          Arel.sql("MAX(scripture_circle_posts.created_at)")
        )

        Activity.new(
          threads: threads.to_i,
          replies: total.to_i - threads.to_i,
          last_at:
        )
      end
  end
end
