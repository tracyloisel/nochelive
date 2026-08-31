module ScriptureCircles
  module Posts
    class Destroy
      def self.call(person:, post_id:)
        access = Access.new(person:)
        post = access.post!(post_id, write: true)
        raise ActiveRecord::RecordNotFound unless post.person_id == person.id

        destroyed_post = ScriptureCirclePost.transaction do
          post.lock!
          proposal = post.scripture_circle_moderation_proposals.open.lock.first
          if proposal
            proposal.update!(status: "canceled_by_author", resolved_at: Time.current)
            proposal.scripture_circle_moderation_events.create!(
              post:, ward: post.ward, actor_person: person, event_type: "canceled_by_author"
            )
          end
          post.update!(status: "author_deleted", deleted_at: Time.current)
          post
        end
        RamaRefresh.call(ward: destroyed_post.ward)
        destroyed_post
      end
    end
  end
end
