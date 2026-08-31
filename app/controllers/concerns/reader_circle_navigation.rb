module ReaderCircleNavigation
  private

    # Only a known reader sort may survive an interaction redirect. Never use
    # a caller-supplied return URL for Circle navigation.
    def reader_circle_sort
      value = params[:circle_sort].to_s
      value if value.in?(ScriptureCircles::ConversationFeed::SORTS)
    end

    def reader_circle_options(post:, event: nil, focus: true)
      {
        locale: post.locale,
        circle: 1,
        circle_post: (post.id if focus && event.blank?),
        circle_event_post: (post.id if event.present?),
        circle_sort: reader_circle_sort,
        circle_event: event
      }.compact
    end
end
