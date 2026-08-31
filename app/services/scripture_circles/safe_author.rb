module ScriptureCircles
  # The single privacy boundary for player-facing Circle author metadata.
  # It supports both complete Post records and the aliased projections used by
  # RamaScreen without returning a Person object or unsafe profile metadata.
  class SafeAuthor
    Result = Data.define(:identity, :name, :avatar_key, :anonymous, :own) do
      def anonymous? = anonymous
      def own? = own
    end

    def self.call(post:, viewer:, ward:, locale: I18n.locale)
      new(post:, viewer:, ward:, locale:).call
    end

    def initialize(post:, viewer:, ward:, locale:)
      @post = post
      @viewer = viewer
      @ward = ward
      @locale = Locale.cast(locale)
    end

    def call
      own = @post.person_id == @viewer&.id
      if anonymous?
        return Result.new(
          identity: [ :anonymous, @post.id ],
          name: own ? translated("scripture_reader.circle.you") : translated("scripture_reader.circle.anonymous"),
          avatar_key: nil,
          anonymous: true,
          own:
        )
      end

      if author_ward_id == @ward.id
        return Result.new(
          identity: [ :person, @post.person_id ],
          name: own ? translated("scripture_reader.circle.you") : author_name,
          avatar_key: author_avatar_key,
          anonymous: false,
          own:
        )
      end

      Result.new(
        identity: [ :former_member, @post.person_id || @post.id ],
        name: translated("scripture_reader.circle.former_member"),
        avatar_key: nil,
        anonymous: false,
        own:
      )
    end

    private

      def anonymous?
        @post.author_visibility == "anonymous_to_ward" || @post.read_attribute("anonymous")
      end

      def projected_author?
        @post.has_attribute?("circle_person_ward_id")
      end

      def author_ward_id
        projected_author? ? @post.read_attribute("circle_person_ward_id") : author_person&.ward_id
      end

      def author_name
        parts = if projected_author?
          [
            @post.read_attribute("circle_person_given_name"),
            @post.read_attribute("circle_person_family_name")
          ]
        else
          [ author_person&.given_name, author_person&.family_name ]
        end

        parts.compact_blank.join(" ").presence || translated("scripture_reader.circle.former_member")
      end

      def author_avatar_key
        value = if projected_author?
          @post.read_attribute("circle_person_avatar_key")
        else
          author_person&.avatar_key
        end
        value.presence
      end

      def author_person
        @author_person ||= @post.person
      end

      def translated(key)
        I18n.t(key, locale: @locale)
      end
  end
end
