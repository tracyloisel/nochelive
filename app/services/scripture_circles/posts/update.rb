module ScriptureCircles
  module Posts
    class Update
      def self.call(person:, post_id:, body:, author_visibility: nil, anonymous: nil)
        post = Access.new(person:).post!(post_id, write: true)
        raise ActiveRecord::RecordNotFound unless post.person_id == person.id
        raise ActiveRecord::RecordInvalid.new(post) if post.status != "visible"

        attributes = { body:, edited_at: Time.current }
        if author_visibility.to_s.present?
          attributes[:author_visibility] = author_visibility
        elsif !anonymous.nil?
          attributes[:author_visibility] = legacy_visibility(post:, anonymous:)
        end
        if attributes[:author_visibility]
          attributes[:anonymous] = attributes[:author_visibility] == "anonymous_to_ward"
        end
        post.update!(attributes)
        RamaRefresh.call(ward: post.ward)
        post
      end

      def self.legacy_visibility(post:, anonymous:)
        return "named" unless ActiveModel::Type::Boolean.new.cast(anonymous)
        return "anonymous_to_ward" if post.question_root?

        "named"
      end
      private_class_method :legacy_visibility
    end
  end
end
