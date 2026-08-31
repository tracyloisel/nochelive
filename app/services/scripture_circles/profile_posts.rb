module ScriptureCircles
  class ProfilePosts
    Result = Data.define(:posts, :owner_view, :next_cursor)

    def self.call(viewer_person:, profile_person:, cursor: nil, limit: 20)
      new(viewer_person:, profile_person:, cursor:, limit:).call
    end

    def self.visible_count(viewer_person:, profile_person:)
      new(viewer_person:, profile_person:, cursor: nil, limit: 1).visible_count
    end

    def initialize(viewer_person:, profile_person:, cursor:, limit:)
      @viewer = viewer_person
      @profile = profile_person
      @cursor = cursor.to_i if cursor.present?
      @limit = limit.to_i.clamp(1, 50)
    end

    def call
      relation = visible_relation
      relation = relation.where("scripture_circle_posts.id < ?", @cursor) if @cursor&.positive?
      rows = relation.order(id: :desc).limit(@limit + 1).to_a
      next_cursor = rows.size > @limit ? rows[@limit - 1].id : nil
      Result.new(posts: rows.first(@limit), owner_view: owner_view?, next_cursor:)
    end

    def visible_count
      visible_relation.count
    end

    private

      def visible_relation
        access = Access.new(person: @viewer).readable!
        return ScriptureCirclePost.none unless same_ward?(access)

        relation = @profile.scripture_circle_posts
          .joins(:scripture_circle_thread)
          .includes(:ward, :scripture_circle_thread)
          .where(ward_id: access.ward.id, status: "visible", scripture_circle_threads: { status: "active" })
        owner_view? ? relation : relation.where(author_visibility: "named")
      end

      def owner_view?
        @viewer.id == @profile.id
      end

      def same_ward?(access)
        @profile.ward_id.present? && @profile.ward_id == access.ward.id
      end
  end
end
