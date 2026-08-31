module ScriptureCircles
  module ConversationVotes
    class Cast
      Result = Data.define(:conversation_root, :vote, :changed)

      def self.call(person:, conversation_root_id:, direction:, device_digest: nil)
        new(person:, conversation_root_id:, direction:, device_digest:).call
      end

      def initialize(person:, conversation_root_id:, direction:, device_digest:)
        @person = person
        @conversation_root_id = conversation_root_id
        @direction = direction.to_s
        @device_digest = device_digest
      end

      def call
        result = cast!
        RamaRefresh.call(ward: result.conversation_root.ward) if result.changed
        result
      end

      private

        def cast!
          ApplicationRecord.transaction do
            changed = false
            vote = nil

            # A transfer locks this same row before changing its ward. Taking
            # that lock first makes the authorization decision and the write
            # one atomic moment: a stale request cannot vote in a former ward.
            voter = Person.lock.find(@person.id)
            access = Access.new(person: voter)
            root = access.post!(@conversation_root_id, write: true)
            root.lock!
            ensure_rankable_root!(root)

            vote = ScriptureCircleConversationVote.lock.find_or_initialize_by(
              conversation_root: root,
              voter_person: voter
            )

            if vote.persisted? && vote.direction == @direction
              RateLimit.check!(action: :conversation_vote, person: voter, device_digest: @device_digest)
              vote.destroy!
              changed = true
              vote = nil
            else
              vote.assign_attributes(ward: access.ward, direction: @direction)
              validate_vote!(vote)
              RateLimit.check!(action: :conversation_vote, person: voter, device_digest: @device_digest)
              vote.save!
              changed = true
            end

            Result.new(conversation_root: root, vote:, changed:)
          end
        end

        def ensure_rankable_root!(root)
          return if root.conversation_root? && root.status == "visible" && root.kind.in?(%w[question reflection])

          raise ActiveRecord::RecordNotFound
        end

        def validate_vote!(vote)
          return if ScriptureCircleConversationVote::DIRECTIONS.include?(@direction) && vote.valid?

          raise ActiveRecord::RecordInvalid.new(vote)
        end
    end
  end
end
