module ScriptureCircles
  # Shared, visibility-safe source for Circle conversation roots. Both the
  # standalone inbox and the reader use this query so score and activity
  # cannot drift apart. Their filters intentionally remain distinct: the
  # reader's `unresolved` treats any visible reply as an answer, whereas the
  # standalone inbox's `help` asks for a reply from another member.
  class ConversationFeed
    SORTS = %w[recent popular unresolved].freeze

    attr_reader :ward

    def self.normalized_sort(value)
      value.to_s.in?(SORTS) ? value.to_s : "recent"
    end

    def initialize(ward:, references: nil, thread_id: nil)
      @ward = ward
      @references = references.nil? ? nil : Array(references).map(&:to_s).uniq
      @thread_id = thread_id
    end

    # Visible question/reflection roots in active Circle threads. Score and
    # activity are pre-aggregated independently, preventing reply/vote joins
    # from multiplying one another.
    def roots
      @roots ||= begin
        scope = ScriptureCirclePost
          .joins(:scripture_circle_thread)
          .where(
            scripture_circle_posts: {
              ward_id: ward.id,
              status: "visible",
              parent_id: nil,
              kind: %w[question reflection]
            },
            scripture_circle_threads: { status: "active" }
          )
          .where("scripture_circle_posts.conversation_root_id = scripture_circle_posts.id")

        scope = scope.where(scripture_circle_threads: { reference: @references }) unless @references.nil?
        scope = scope.where(scripture_circle_threads: { id: @thread_id }) if @thread_id

        scope
          .joins(conversation_stats_join)
          .joins(conversation_vote_stats_join)
          .select(<<~SQL.squish)
            scripture_circle_posts.*,
            scripture_circle_threads.reference AS circle_reference,
            circle_stats.reply_count AS circle_reply_count,
            circle_stats.last_activity_at AS circle_last_activity_at,
            COALESCE(circle_vote_stats.score, 0) AS circle_vote_score
          SQL
      end
    end

    # A question is unresolved only while no reply remains renderable through
    # the complete visible ancestor chain. A reply by the author still resolves
    # it: this is a status, not the standalone inbox's request-for-help signal.
    def unresolved_roots
      roots
        .where(kind: "question")
        .where(<<~SQL.squish)
          NOT EXISTS (
            SELECT 1
            FROM (#{renderable_posts_sql}) AS visible_reply
            WHERE visible_reply.conversation_root_id = scripture_circle_posts.id
              AND visible_reply.scripture_circle_thread_id = scripture_circle_posts.scripture_circle_thread_id
              AND visible_reply.ward_id = scripture_circle_posts.ward_id
              AND visible_reply.kind = 'reply'
          )
        SQL
    end

    def ordered(scope, sort:)
      case self.class.normalized_sort(sort)
      when "popular"
        scope.order(
          Arel.sql("COALESCE(circle_vote_stats.score, 0) DESC"),
          Arel.sql("circle_stats.last_activity_at DESC"),
          Arel.sql("scripture_circle_posts.created_at DESC"),
          Arel.sql("scripture_circle_posts.id DESC")
        )
      else
        scope.order(
          Arel.sql("circle_stats.last_activity_at DESC"),
          Arel.sql("scripture_circle_posts.created_at DESC"),
          Arel.sql("scripture_circle_posts.id DESC")
        )
      end
    end

    # Reused by the standalone inbox's intentional `help` predicate as well
    # as this feed's unresolved predicate. The recursive path ensures that a
    # visible descendant below a censored/deleted ancestor is not content,
    # activity, or a resolution.
    def renderable_posts_sql
      @renderable_posts_sql ||= <<~SQL.squish
        #{renderable_posts_cte}
        SELECT id,
               conversation_root_id,
               scripture_circle_thread_id,
               ward_id,
               kind,
               person_id,
               created_at
        FROM renderable_posts
      SQL
    end

    private

      def conversation_stats_join
        @conversation_stats_join ||= <<~SQL.squish
          INNER JOIN (#{conversation_stats_sql}) AS circle_stats
            ON circle_stats.conversation_root_id = scripture_circle_posts.id
           AND circle_stats.scripture_circle_thread_id = scripture_circle_posts.scripture_circle_thread_id
        SQL
      end

      def conversation_vote_stats_join
        @conversation_vote_stats_join ||= <<~SQL.squish
          LEFT JOIN (
            SELECT conversation_root_id,
                   SUM(CASE direction WHEN 'up' THEN 1 WHEN 'down' THEN -1 ELSE 0 END) AS score
            FROM scripture_circle_conversation_votes
            WHERE ward_id = #{quoted_ward_id}
            GROUP BY conversation_root_id
          ) AS circle_vote_stats
            ON circle_vote_stats.conversation_root_id = scripture_circle_posts.id
        SQL
      end

      def renderable_posts_cte
        @renderable_posts_cte ||= <<~SQL.squish
          WITH RECURSIVE renderable_posts AS (
            SELECT root.id,
                   root.conversation_root_id,
                   root.scripture_circle_thread_id,
                   root.ward_id,
                   root.kind,
                   root.person_id,
                   root.created_at,
                   ARRAY[root.id] AS path
            FROM scripture_circle_posts AS root
            INNER JOIN scripture_circle_threads AS root_thread
              ON root_thread.id = root.scripture_circle_thread_id
             AND root_thread.ward_id = root.ward_id
             AND root_thread.status = 'active'
            WHERE root.ward_id = #{quoted_ward_id}
              AND root.status = 'visible'
              AND root.parent_id IS NULL
              AND root.conversation_root_id = root.id
              #{reference_predicate("root_thread.reference")}
              #{thread_predicate("root.scripture_circle_thread_id")}

            UNION ALL

            SELECT child.id,
                   child.conversation_root_id,
                   child.scripture_circle_thread_id,
                   child.ward_id,
                   child.kind,
                   child.person_id,
                   child.created_at,
                   renderable_posts.path || child.id AS path
            FROM scripture_circle_posts AS child
            INNER JOIN renderable_posts ON child.parent_id = renderable_posts.id
            WHERE child.ward_id = #{quoted_ward_id}
              AND child.status = 'visible'
              AND child.conversation_root_id = renderable_posts.conversation_root_id
              AND child.scripture_circle_thread_id = renderable_posts.scripture_circle_thread_id
              AND NOT (child.id = ANY(renderable_posts.path))
          )
        SQL
      end

      def conversation_stats_sql
        @conversation_stats_sql ||= <<~SQL.squish
          #{renderable_posts_cte}
          SELECT conversation_root_id,
                 scripture_circle_thread_id,
                 COUNT(*) FILTER (WHERE kind = 'reply') AS reply_count,
                 MAX(created_at) AS last_activity_at
          FROM renderable_posts
          GROUP BY conversation_root_id, scripture_circle_thread_id
        SQL
      end

      def quoted_ward_id
        @quoted_ward_id ||= ScriptureCirclePost.connection.quote(ward.id)
      end

      def reference_predicate(column)
        return "" if @references.nil?
        return "AND FALSE" if @references.empty?

        quoted_references = @references.map { |reference| ScriptureCirclePost.connection.quote(reference) }.join(", ")
        "AND #{column} IN (#{quoted_references})"
      end

      def thread_predicate(column)
        return "" unless @thread_id

        "AND #{column} = #{ScriptureCirclePost.connection.quote(@thread_id)}"
      end
  end
end
