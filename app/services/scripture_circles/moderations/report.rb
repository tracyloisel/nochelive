module ScriptureCircles
  module Moderations
    class Report
      THRESHOLD = 3
      VOTE_DURATION = 2.days
      Result = Data.define(:report, :proposal, :opened)

      def self.call(person:, post_id:, reason_key:, reason_details: nil, device_digest: nil, at: Time.current)
        access = Access.new(person:)
        post = access.post!(post_id, write: true)
        RateLimit.check!(action: :report, person:, device_digest:)

        result = ScriptureCircleModerationReport.transaction do
          post.lock!
          raise ActiveRecord::RecordInvalid.new(post) unless post.status == "visible"

          report = post.scripture_circle_moderation_reports.find_or_initialize_by(reporter_person: person)
          report.assign_attributes(ward: post.ward, reason_key:, reason_details:)
          report.save!

          proposal = nil
          opened = false
          if post.scripture_circle_moderation_reports.distinct.count(:reporter_person_id) >= THRESHOLD
            proposal = open_vote!(post:, reporter: person, report:, at:)
            opened = proposal.present?
          end

          Result.new(report:, proposal:, opened:)
        end
        RamaRefresh.call(ward: post.ward) if result.opened
        result
      end

      def self.open_vote!(post:, reporter:, report:, at:)
        return post.scripture_circle_moderation_proposals.open.first if post.scripture_circle_moderation_proposals.open.exists?

        snapshot = post.append_revision!(change_kind: "vote_snapshot", editor_person: reporter)
        proposal = post.scripture_circle_moderation_proposals.create!(
          ward: post.ward,
          proposer_person: reporter,
          post_revision: snapshot,
          reason_key: report.reason_key,
          reason_details: report.reason_details,
          starts_at: at,
          ends_at: at + VOTE_DURATION,
          policy_version: ScriptureCircleModerationProposal::POLICY_VERSION
        )
        post.update!(status: "vote_open")
        proposal.scripture_circle_moderation_events.create!(
          post:,
          ward: post.ward,
          actor_person: reporter,
          event_type: "opened",
          metadata: {
            policy_version: proposal.policy_version,
            ends_at: proposal.ends_at.iso8601,
            independent_report_count: THRESHOLD
          }
        )
        proposal
      end
      private_class_method :open_vote!
    end
  end
end
