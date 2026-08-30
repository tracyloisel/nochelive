module ScriptureCircles
  module Moderations
    class Propose
      DURATION = 2.days

      def self.call(person:, post_id:, reason_key:, reason_details: nil, device_digest: nil, at: Time.current)
        access = Access.new(person:)
        post = access.post!(post_id, write: true)
        RateLimit.check!(action: :proposal, person:, device_digest:)

        ScriptureCircleModerationProposal.transaction do
          post.lock!
          raise ActiveRecord::RecordInvalid.new(post) unless post.status == "visible"
          if post.scripture_circle_moderation_proposals.open.exists?
            raise ActiveRecord::RecordNotUnique, "moderation already open"
          end

          snapshot = post.append_revision!(change_kind: "vote_snapshot", editor_person: person)
          proposal = post.scripture_circle_moderation_proposals.create!(
            ward: post.ward,
            proposer_person: person,
            post_revision: snapshot,
            reason_key:,
            reason_details: reason_details.to_s.squish.presence,
            starts_at: at,
            ends_at: at + DURATION,
            policy_version: ScriptureCircleModerationProposal::POLICY_VERSION
          )
          post.update!(status: "vote_open")
          proposal.scripture_circle_moderation_events.create!(
            post:, ward: post.ward, actor_person: person, event_type: "opened",
            metadata: { policy_version: proposal.policy_version, ends_at: proposal.ends_at.iso8601 }
          )
          proposal
        end
      end
    end
  end
end
