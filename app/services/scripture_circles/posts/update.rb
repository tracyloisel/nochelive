module ScriptureCircles
  module Posts
    class Update
      def self.call(person:, post_id:, body:, anonymous: nil)
        post = Access.new(person:).post!(post_id, write: true)
        raise ActiveRecord::RecordNotFound unless post.person_id == person.id
        raise ActiveRecord::RecordInvalid.new(post) if post.status != "visible"

        attributes = { body:, edited_at: Time.current }
        attributes[:anonymous] = anonymous unless anonymous.nil?
        post.update!(attributes)
        post
      end
    end
  end
end
