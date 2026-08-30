require "digest"

module ScriptureCircles
  module Moderations
    class ResolveDue
      MINIMUM_BALLOTS = 3
      BATCH_SIZE = 50

      def self.call(at: Time.current, limit: BATCH_SIZE)
        ScriptureCircleModerationProposal.due(at).order(:ends_at, :id).limit(limit).filter_map do |proposal|
          resolve_one(proposal, at:)
        end
      end

      def self.resolve_one(proposal, at: Time.current)
        ScriptureCircleModerationProposal.transaction do
          proposal.lock!
          next unless proposal.open? && proposal.ends_at <= at

          proposal.scripture_circle_moderation_events.create!(
            post: proposal.scripture_circle_post, ward: proposal.ward,
            event_type: "resolution_started", metadata: { attempt_at: at.iso8601 }
          )
          counts = proposal.scripture_circle_moderation_ballots.group(:choice).count
          yes = counts.fetch("yes", 0)
          no = counts.fetch("no", 0)
          total = yes + no
          censored = total >= MINIMUM_BALLOTS && yes > no
          status = censored ? "censored" : "kept"
          post_status = censored ? "community_censored" : "visible"
          digest = Digest::SHA256.hexdigest(
            [ proposal.id, proposal.policy_version, yes, no, total, status ].join(":")
          )

          proposal.scripture_circle_post.update!(status: post_status)
          proposal.update!(
            status:, resolved_at: at, yes_count: yes, no_count: no,
            valid_ballot_count: total, result_digest: digest
          )
          proposal.scripture_circle_moderation_events.create!(
            post: proposal.scripture_circle_post, ward: proposal.ward,
            event_type: "resolved",
            metadata: { result: status, yes_count: yes, no_count: no, valid_ballot_count: total }
          )
          proposal
        end
      rescue StandardError => error
        record_failure(proposal, error, at:)
        raise
      end

      def self.record_failure(proposal, error, at:)
        return unless proposal&.persisted?
        proposal.scripture_circle_moderation_events.create!(
          post: proposal.scripture_circle_post, ward: proposal.ward,
          event_type: "resolution_failed",
          metadata: { error_class: error.class.name, failed_at: at.iso8601 }
        )
      rescue ActiveRecord::ActiveRecordError
        nil
      end
      private_class_method :record_failure
    end
  end
end
