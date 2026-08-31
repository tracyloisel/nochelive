module Scriptures
  class ReaderScreen
    CIRCLE_CONVERSATION_PREVIEW_LIMIT = 20
    EMPTY_CIRCLE_COUNTS = { recent: 0, popular: 0, unresolved: 0 }.freeze

    Result = Data.define(
      :preference, :progress, :marks, :guide, :movement, :circle_mode, :circle_sort, :circle_counts, :circle_thread,
      :circle_posts, :circle_focus_post, :circle_focus_unavailable,
      :video_links, :chapter_history
    )

    def self.call(person:, reference:, locale:, circle_post_id: nil, circle_sort: nil)
      new(person:, reference:, locale:, circle_post_id:, circle_sort:).call
    end

    def initialize(person:, reference:, locale:, circle_post_id:, circle_sort:)
      @person = person
      @reference = reference
      @locale = Locale.cast(locale)
      @circle_post_id = circle_post_id
      @circle_sort = ScriptureCircles::ConversationFeed.normalized_sort(circle_sort)
    end

    def call
      preference = @person&.scripture_reader_preference || ScriptureReaderPreference.new
      progress = @person&.scripture_reading_progresses&.find_by(reference: @reference, locale: @locale)
      marks = @person ? @person.scripture_marks.includes(:scripture_tags, :scripture_notebooks, :scripture_mark_links).for_reader(reference: @reference, locale: @locale).to_a : []
      guide = ScriptureChapterGuide.published.find_by(reference: @reference, locale: @locale)
      movement = Scriptures::WardMovement.call(person: @person, reference: @reference)
      circle_mode = @person&.ward&.scripture_circle_mode || "disabled"
      thread, posts, focus_post, focus_unavailable, circle_counts = circle_preview(circle_mode)
      videos = ScriptureVideoLink.published.where(reference: @reference, locale: @locale).limit(3).to_a
      chapter_history = Scriptures::ChapterHistory.call(
        person: @person, reference: @reference, locale: @locale, marks:, progress:
      )

      Result.new(
        preference:, progress:, marks:, guide:, movement:, circle_mode:, circle_sort: @circle_sort, circle_counts:,
        circle_thread: thread, circle_posts: posts,
        circle_focus_post: focus_post, circle_focus_unavailable: focus_unavailable,
        video_links: videos, chapter_history:
      )
    end

    private

      def circle_preview(mode)
        requested_focus = @circle_post_id.present?
        return [ nil, [], nil, requested_focus, EMPTY_CIRCLE_COUNTS ] unless @person&.ward_id && mode.in?(%w[read_only active])

        access = ScriptureCircles::Access.new(person: @person).readable!
        thread = access.ward.scripture_circle_threads.where(reference: @reference, status: "active").first
        return [ nil, [], nil, requested_focus, EMPTY_CIRCLE_COUNTS ] unless thread

        feed = ScriptureCircles::ConversationFeed.new(ward: access.ward, thread_id: thread.id)
        roots = sorted_conversation_roots(feed).limit(CIRCLE_CONVERSATION_PREVIEW_LIMIT).to_a
        focus_post = resolve_circle_focus(thread)
        roots = include_focus_root(roots, focus_post, feed) if focus_post
        roots.concat(moderated_roots(thread).reject { |root| roots.any? { |candidate| candidate.id == root.id } })

        [ thread, grouped_conversation_posts(thread, roots), focus_post,
          requested_focus && focus_post.nil?, circle_counts_for(feed) ]
      rescue ScriptureCircles::Access::Error
        [ nil, [], nil, requested_focus, EMPTY_CIRCLE_COUNTS ]
      end

      def sorted_conversation_roots(feed)
        scope = @circle_sort == "unresolved" ? feed.unresolved_roots : feed.roots
        feed.ordered(scope, sort: @circle_sort).includes(*reader_includes)
      end

      def circle_counts_for(feed)
        visible_count = conversation_count(feed.roots)
        { recent: visible_count, popular: visible_count, unresolved: conversation_count(feed.unresolved_roots) }.freeze
      end

      def conversation_count(scope)
        scope.except(:select, :order).count
      end

      def resolve_circle_focus(thread)
        post_id = Integer(@circle_post_id, exception: false)
        return unless post_id&.positive?

        post = reader_posts(thread).find_by(id: post_id)
        return unless post

        root = conversation_root_for(post)
        return post if post.id == root&.id && root.status.in?(%w[vote_open community_censored])
        return unless post.status.in?(%w[visible community_censored]) && root&.status.in?(%w[visible community_censored])
        return unless root.scripture_circle_thread_id == thread.id

        visible_conversation_post?(post, root, ancestry: conversation_ancestry(thread, root)) ? post : nil
      end

      def conversation_root_for(post)
        post.conversation_root || post
      end

      # A focused reply may sit many levels below its root. Fetch its tree once
      # instead of walking parent associations one SQL query at a time.
      def conversation_ancestry(thread, root)
        @conversation_ancestries ||= {}
        @conversation_ancestries[[ thread.id, root.id ]] ||= thread.scripture_circle_posts
          .where(ward_id: thread.ward_id, conversation_root_id: root.id)
          .pluck(:id, :parent_id, :status)
          .to_h { |id, parent_id, status| [ id, { parent_id:, status: } ] }
      end

      def visible_conversation_post?(post, root, ancestry:)
        current_id = post.id
        seen = {}
        while current_id && !seen[current_id]
          current = ancestry[current_id]
          return false unless current && current[:status].in?(%w[visible community_censored])
          return true if current_id == root.id

          seen[current_id] = true
          current_id = current[:parent_id]
        end

        false
      end

      def include_focus_root(roots, focus_post, feed)
        root = conversation_root_for(focus_post)
        return roots unless root
        return roots if roots.any? { |candidate| candidate.id == root.id }

        # Keep a direct, visible link useful if its question gained a reply
        # between the click and reload, moving it out of `unresolved`.
        ranked_root = feed.ordered(feed.roots, sort: @circle_sort).includes(*reader_includes).find_by(id: root.id)
        ranked_root ? roots + [ ranked_root ] : roots
      end

      # Open votes and community-masked roots remain present as history even
      # though ranked feeds contain only visible roots. They do not affect
      # counts or ranking.
      def moderated_roots(thread)
        reader_posts(thread)
          .where(parent_id: nil, status: %w[vote_open community_censored], kind: %w[question reflection])
          .where("scripture_circle_posts.conversation_root_id = scripture_circle_posts.id")
          .order(created_at: :desc, id: :desc)
          .to_a
      end

      def grouped_conversation_posts(thread, roots)
        return [] if roots.empty?

        root_ids = roots.map(&:id)
        descendants_by_root = reader_posts(thread)
          .where(conversation_root_id: root_ids)
          .where.not(id: root_ids)
          .to_a
          .group_by(&:conversation_root_id)

        roots.flat_map do |root|
          ordered_conversation_posts(root, descendants_by_root.fetch(root.id, []))
        end
      end

      # Root first, then chronological replies depth-first. A community-masked
      # reply leaves a reversible trace and therefore keeps its descendants in
      # the history; an author-deleted reply remains a hard branch boundary.
      def ordered_conversation_posts(root, descendants)
        children_by_parent = descendants.group_by(&:parent_id)
        ordered = [ root ]
        seen = { root.id => true }

        append_children = lambda do |parent_id, ancestors_visible|
          return unless ancestors_visible

          Array(children_by_parent[parent_id]).sort_by { |post| [ post.created_at, post.id ] }.each do |post|
            next if seen[post.id]

            seen[post.id] = true
            ordered << post
            append_children.call(post.id, post.status.in?(%w[visible community_censored]))
          end
        end

        append_children.call(root.id, root.status.in?(%w[visible community_censored]))
        ordered
      end

      def reader_posts(thread)
        thread.scripture_circle_posts.where(ward_id: thread.ward_id).includes(*reader_includes)
      end

      def reader_includes
        [
          :person,
          :parent,
          :conversation_root,
          :scripture_circle_conversation_votes,
          :scripture_circle_post_votes,
          :scripture_circle_moderation_reports,
          { scripture_circle_moderation_proposals: [ :proposer_person, :scripture_circle_moderation_ballots ] }
        ]
      end
  end
end
