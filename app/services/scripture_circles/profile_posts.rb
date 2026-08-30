module ScriptureCircles
  class ProfilePosts
    Result = Data.define(:posts, :owner_view, :next_cursor)

    def self.call(viewer_person:, profile_person:, cursor: nil, limit: 20)
      new(viewer_person:, profile_person:, cursor:, limit:).call
    end

    def initialize(viewer_person:, profile_person:, cursor:, limit:)
      @viewer = viewer_person
      @profile = profile_person
      @cursor = cursor.to_i if cursor.present?
      @limit = limit.to_i.clamp(1, 50)
    end

    def call
      raise Access::MissingIdentity unless @viewer

      owner = @viewer.id == @profile.id
      relation = @profile.scripture_circle_posts.includes(:ward, :scripture_circle_thread)
      unless owner
        same_ward = @viewer.ward_id.present? && @viewer.ward_id == @profile.ward_id
        relation = same_ward ? relation.where(ward_id: @viewer.ward_id, anonymous: false, status: %w[visible vote_open community_censored]) : relation.none
      end
      relation = relation.where("scripture_circle_posts.id < ?", @cursor) if @cursor&.positive?
      rows = relation.order(id: :desc).limit(@limit + 1).to_a
      next_cursor = rows.size > @limit ? rows[@limit - 1].id : nil
      Result.new(posts: rows.first(@limit), owner_view: owner, next_cursor:)
    end
  end
end
