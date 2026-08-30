module ScriptureCircles
  module Moderations
    class History
      Result = Data.define(:proposal, :events, :own_ballot, :own_revisions)

      def self.call(person:, proposal_id:)
        proposal = Access.new(person:).proposal!(proposal_id)
        ballot = proposal.scripture_circle_moderation_ballots.find_by(voter_person: person)
        Result.new(
          proposal:,
          events: proposal.scripture_circle_moderation_events.order(:created_at, :id).to_a,
          own_ballot: ballot,
          own_revisions: ballot ? ballot.scripture_circle_moderation_ballot_revisions.order(:created_at, :id).to_a : []
        )
      end
    end
  end
end
