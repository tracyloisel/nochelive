module ScriptureCircles
  module Moderations
    class CastBallot
      def self.call(person:, proposal_id:, choice:, device_digest: nil, at: Time.current)
        access = Access.new(person:)
        proposal = access.proposal!(proposal_id, write: true)
        RateLimit.check!(action: :ballot, person:, device_digest:)

        ScriptureCircleModerationProposal.transaction do
          proposal.lock!
          raise ActiveRecord::RecordInvalid.new(proposal) unless proposal.open? && proposal.ends_at > at

          ballot = proposal.scripture_circle_moderation_ballots.find_or_initialize_by(voter_person: person)
          previous = ballot.choice
          ballot.ward = proposal.ward
          ballot.choice = choice
          ballot.cast_at ||= at
          ballot.updated_at = at
          ballot.save!
          ballot.scripture_circle_moderation_ballot_revisions.create!(
            proposal:, ward: proposal.ward, voter_person: person,
            previous_choice: previous.presence, new_choice: ballot.choice, created_at: at
          )
          proposal.scripture_circle_moderation_events.create!(
            post: proposal.scripture_circle_post,
            ward: proposal.ward,
            actor_person: person,
            event_type: previous.present? ? "ballot_changed" : "ballot_cast"
          )
          recount!(proposal, at:)
          ballot
        end
      end

      def self.recount!(proposal, at: Time.current)
        counts = proposal.scripture_circle_moderation_ballots.group(:choice).count
        yes = counts.fetch("yes", 0)
        no = counts.fetch("no", 0)
        proposal.update_columns(
          yes_count: yes,
          no_count: no,
          valid_ballot_count: yes + no,
          updated_at: at
        )
        proposal.reload
      end
      private_class_method :recount!
    end
  end
end
