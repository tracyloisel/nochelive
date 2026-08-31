module ScriptureCircles
  # Read model for the ward-wide Circle inbox. It intentionally starts from
  # conversation roots: a reply must never become a separate inbox item.
  #
  # Everything handed to the view is an immutable value object. In
  # particular, Circle views never receive a Post or Person record, which
  # keeps anonymous authorship from being accidentally revealed by a new
  # partial or helper.
  class RamaScreen
    PAGE_SIZE = 12
    MAX_PAGE = 10_000

    Result = Data.define(
      :state,
      :ward,
      :conversations,
      :help_count,
      :active_view,
      :page,
      :next_page,
      :selected,
      :selected_explicitly
    )

    # The chapter is the conversation's sender. reader_path deliberately
    # opens the reading experience only; selecting an exchange stays in the
    # Circle inbox.
    Chapter = Data.define(:reference, :title, :reader_path)

    # A complete, safely displayable message. No association or person id is
    # exposed here: anonymous authorship therefore cannot leak through a view
    # that happens to inspect a row more deeply than intended.
    ConversationRow = Data.define(
      :id,
      :parent_id,
      :body,
      :selected_text,
      :created_at,
      :author_name,
      :avatar_key,
      :anonymous,
      :own
    ) do
      def root? = parent_id.nil?
      def reply? = !root?
      def anonymous? = anonymous
      def own? = own
    end

    # Useful for the compact participant stack without exposing people or the
    # internal identity key used to aggregate a participant's messages.
    Participant = Data.define(
      :name,
      :avatar_key,
      :anonymous
    ) do
      def anonymous? = anonymous
      def own? = own
    end

    Card = Data.define(
      :root_id,
      :conversation,
      :participants,
      :chapter,
      :reply_count
    ) do
      def root = conversation.first
    end

    def self.call(person:, locale:, view: nil, page: nil, conversation: nil)
      new(person:, locale:, view:, page:, conversation:).call
    end

    def initialize(person:, locale:, view:, page:, conversation:)
      @person = person
      @locale = Locale.cast(locale)
      @requested_view = view.to_s
      @requested_conversation_id = normalized_conversation_id(conversation)
      @page = (Integer(page, exception: false) || 1).clamp(1, MAX_PAGE)
      @routes = Rails.application.routes.url_helpers
    end

    def call
      @access = Access.new(person: @person).readable!
      @ward = @access.ward
      @references_by_study = Scriptures::Reference.chapters(@locale).index_by(&:study)
      @conversation_feed = ConversationFeed.new(ward: @ward, references: @references_by_study.keys)

      help_scope = help_conversations
      mine_scope = mine_conversations

      help_count = conversation_count(help_scope)
      @active_view = normalized_view
      conversations, next_page = cards_for(active_conversations(
        mine_scope:
      ))
      selected, selected_explicitly = select_conversation(conversations)

      Result.new(
        state: @ward.scripture_circle_mode,
        ward: @ward,
        conversations:,
        help_count:,
        active_view: @active_view,
        page: @page,
        next_page:,
        selected:,
        selected_explicitly:
      )
    end

    private

      def normalized_conversation_id(value)
        id = Integer(value, exception: false)
        id if id&.positive?
      end

      def normalized_view
        return "mine" if @requested_view == "mine"

        # Keep old shared links working after the help/recent feeds were merged.
        "all"
      end

      def root_conversations
        @root_conversations ||= @conversation_feed.roots
      end

      def renderable_posts_sql
        @conversation_feed.renderable_posts_sql
      end

      def help_conversations
        root_conversations
          .where(kind: "question")
          .where("scripture_circle_posts.person_id IS DISTINCT FROM ?", @person.id)
          .where(<<~SQL.squish)
            NOT EXISTS (
              SELECT 1
              FROM (#{renderable_posts_sql}) AS qualifying_reply
              WHERE qualifying_reply.conversation_root_id = scripture_circle_posts.id
                AND qualifying_reply.scripture_circle_thread_id = scripture_circle_posts.scripture_circle_thread_id
                AND qualifying_reply.ward_id = scripture_circle_posts.ward_id
                AND qualifying_reply.kind = 'reply'
                AND qualifying_reply.person_id IS DISTINCT FROM scripture_circle_posts.person_id
            )
          SQL
      end

      def mine_conversations
        root_conversations.where(<<~SQL.squish, @person.id)
          EXISTS (
            SELECT 1
            FROM (#{renderable_posts_sql}) AS participant_post
            WHERE participant_post.conversation_root_id = scripture_circle_posts.id
              AND participant_post.scripture_circle_thread_id = scripture_circle_posts.scripture_circle_thread_id
              AND participant_post.ward_id = scripture_circle_posts.ward_id
              AND participant_post.person_id = ?
          )
        SQL
      end

      def active_conversations(mine_scope:)
        case @active_view
        when "mine" then mine_scope
        else root_conversations
        end
      end

      def conversation_count(scope)
        scope.except(:select, :order).count
      end

      def cards_for(scope)
        roots = ordered(scope)
          .offset((@page - 1) * PAGE_SIZE)
          .limit(PAGE_SIZE + 1)
          .to_a
        more = roots.length > PAGE_SIZE
        roots = roots.first(PAGE_SIZE)
        payload_by_root = conversation_payloads_for(roots)
        cards = roots.filter_map do |root|
          payload = payload_by_root[root.id]
          card_for(root, **payload) if payload
        end

        [ cards, more ? @page + 1 : nil ]
      end

      # Fetch all of this page's conversations in one query. The CTE used for
      # counts is joined again here so display data has exactly the same
      # moderation boundary: a visible descendant below a censored or deleted
      # ancestor never reaches an inbox row.
      def conversation_payloads_for(roots)
        root_ids = roots.map(&:id)
        return {} if root_ids.empty?

        renderable_conversation_posts(root_ids)
          .group_by(&:conversation_root_id)
          .each_with_object({}) do |(root_id, posts), payloads|
            ordered_posts = ordered_conversation_posts(root_id, posts)
            next if ordered_posts.empty?

            conversation, participants = display_conversation(ordered_posts)
            payloads[root_id] = { conversation:, participants: }
          end
      end

      def renderable_conversation_posts(root_ids)
        ScriptureCirclePost
          .joins(<<~SQL.squish)
            INNER JOIN (#{renderable_posts_sql}) AS renderable_post
              ON renderable_post.id = scripture_circle_posts.id
             AND renderable_post.conversation_root_id = scripture_circle_posts.conversation_root_id
             AND renderable_post.scripture_circle_thread_id = scripture_circle_posts.scripture_circle_thread_id
             AND renderable_post.ward_id = scripture_circle_posts.ward_id
            LEFT JOIN people AS circle_person
              ON circle_person.id = scripture_circle_posts.person_id
          SQL
          .where("renderable_post.conversation_root_id IN (?)", root_ids)
          .select(<<~SQL.squish)
            scripture_circle_posts.id,
            scripture_circle_posts.conversation_root_id,
            scripture_circle_posts.parent_id,
            scripture_circle_posts.body,
            scripture_circle_posts.selected_text,
            scripture_circle_posts.created_at,
            scripture_circle_posts.person_id,
            scripture_circle_posts.author_visibility,
            scripture_circle_posts.anonymous,
            circle_person.ward_id AS circle_person_ward_id,
            circle_person.given_name AS circle_person_given_name,
            circle_person.family_name AS circle_person_family_name,
            circle_person.avatar_key AS circle_person_avatar_key
          SQL
          .to_a
      end

      # Root first, then visible replies in chronological depth-first order.
      # The iterative walk makes even a very deep legitimate thread safe to
      # render without a Ruby recursion ceiling.
      def ordered_conversation_posts(root_id, posts)
        root = posts.find { |post| post.id == root_id && post.parent_id.nil? }
        return [] unless root

        children_by_parent = posts.group_by(&:parent_id)
        ordered = []
        seen = {}
        stack = [ root ]

        until stack.empty?
          post = stack.pop
          next if seen[post.id]

          seen[post.id] = true
          ordered << post
          children = Array(children_by_parent[post.id]).sort_by { |child| [ child.created_at, child.id ] }
          children.reverse_each { |child| stack << child }
        end

        ordered
      end

      def display_conversation(ordered_posts)
        participant_states = {}
        conversation = ordered_posts.map do |post|
          author = safe_author_for(post)
          record_participant!(participant_states, author:)
          ConversationRow.new(
            id: post.id,
            parent_id: post.parent_id,
            body: post.body,
            selected_text: post.selected_text,
            created_at: post.created_at,
            author_name: author.fetch(:name),
            avatar_key: author.fetch(:avatar_key),
            anonymous: author.fetch(:anonymous),
            own: author.fetch(:own)
          )
        end

        [ conversation.freeze, participant_states.values.freeze ]
      end

      def safe_author_for(post)
        anonymous = post.author_visibility == "anonymous_to_ward" || post.read_attribute("anonymous")
        own = post.person_id == @person.id

        if anonymous
          return {
            identity: [ :anonymous, post.id ],
            name: own ? translated("scripture_reader.circle.you") : translated("scripture_reader.circle.anonymous"),
            avatar_key: nil,
            anonymous: true,
            own:
          }
        end

        if post.read_attribute("circle_person_ward_id") == @ward.id
          name = [
            post.read_attribute("circle_person_given_name"),
            post.read_attribute("circle_person_family_name")
          ].compact_blank.join(" ").presence || translated("scripture_reader.circle.former_member")
          return {
            identity: [ :person, post.person_id ],
            name: own ? translated("scripture_reader.circle.you") : name,
            avatar_key: post.read_attribute("circle_person_avatar_key").presence,
            anonymous: false,
            own:
          }
        end

        {
          identity: [ :former_member, post.person_id || post.id ],
          name: translated("scripture_reader.circle.former_member"),
          avatar_key: nil,
          anonymous: false,
          own:
        }
      end

      def record_participant!(states, author:)
        identity = author.fetch(:identity)
        return if states.key?(identity)

        states[identity] = Participant.new(
          name: author.fetch(:name),
          avatar_key: author.fetch(:avatar_key),
          anonymous: author.fetch(:anonymous)
        )
      end

      def translated(key)
        I18n.t(key, locale: @locale)
      end

      def card_for(root, conversation:, participants:)
        reference = root.read_attribute("circle_reference")
        reference_data = @references_by_study.fetch(reference)
        root_id = root.id
        chapter = Chapter.new(
          reference:,
          title: reference_data.citation,
          reader_path: @routes.scripture_path(reference)
        )

        Card.new(
          root_id:,
          conversation:,
          participants:,
          chapter:,
          reply_count: root.read_attribute("circle_reply_count").to_i
        )
      end

      def select_conversation(cards)
        return [ cards.first, false ] unless @requested_conversation_id

        visible_in_inbox = cards.find { |card| card.root_id == @requested_conversation_id }
        return [ visible_in_inbox, true ] if visible_in_inbox

        selected = selected_card_for_requested_conversation
        return [ selected, true ] if selected

        [ cards.first, false ]
      end

      # A selection is a direct, shareable address to one visible Circle
      # thread. Keep it open even if an activity update moves it out of the
      # current inbox filter; otherwise a member's draft would disappear just
      # when they choose to refresh it.
      def selected_card_for_requested_conversation
        root = ordered(root_conversations.where(id: @requested_conversation_id)).first
        return unless root

        payload = conversation_payloads_for([ root ])[root.id]
        card_for(root, **payload) if payload
      end

      def ordered(scope)
        @conversation_feed.ordered(scope, sort: "popular")
      end
  end
end
