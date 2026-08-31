module ScriptureCircles
  module PostVotes
    class Cast
      Result = Data.define(:post, :vote, :changed)

      def self.call(person:, post_id:, direction:, device_digest: nil)
        new(person:, post_id:, direction:, device_digest:).call
      end

      def initialize(person:, post_id:, direction:, device_digest:)
        @person = person
        @post_id = post_id
        @direction = direction.to_s
        @device_digest = device_digest
      end

      def call
        result = cast!
        RamaRefresh.call(ward: result.post.ward) if result.changed
        result
      end

      private

        def cast!
          ApplicationRecord.transaction do
            voter = Person.lock.find(@person.id)
            access = Access.new(person: voter)
            post = access.post!(@post_id, write: true)
            post.lock!
            raise ActiveRecord::RecordNotFound unless post.parent_id.present? && post.kind == "reply" && post.status == "visible"

            vote = ScriptureCirclePostVote.lock.find_or_initialize_by(
              scripture_circle_post: post,
              voter_person: voter
            )

            if vote.persisted? && vote.direction == @direction
              RateLimit.check!(action: :post_vote, person: voter, device_digest: @device_digest)
              vote.destroy!
              vote = nil
            else
              vote.assign_attributes(ward: access.ward, direction: @direction)
              unless ScriptureCirclePostVote::DIRECTIONS.include?(@direction) && vote.valid?
                raise ActiveRecord::RecordInvalid.new(vote)
              end
              RateLimit.check!(action: :post_vote, person: voter, device_digest: @device_digest)
              vote.save!
            end

            Result.new(post:, vote:, changed: true)
          end
        end
    end
  end
end
