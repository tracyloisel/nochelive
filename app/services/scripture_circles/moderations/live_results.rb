module ScriptureCircles
  module Moderations
    class LiveResults
      def self.call(person:, proposal_id:)
        proposal = Access.new(person:).proposal!(proposal_id)
        ballot = proposal.scripture_circle_moderation_ballots.find_by(voter_person: person)
        proposal.results_payload.merge(
          own_choice: ballot&.choice,
          own_vote_updated_at: ballot&.updated_at&.iso8601
        )
      end
    end
  end
end
