module People
  class Update
    UNSET = Object.new.freeze

    def self.call(person:, given_name: UNSET, family_name: UNSET, avatar_key: UNSET, favorite_year: UNSET)
      new(person:, given_name:, family_name:, avatar_key:, favorite_year:).call
    end

    def initialize(person:, given_name:, family_name:, avatar_key:, favorite_year:)
      @person = person
      @given_name = normalize_name(given_name)
      @family_name = normalize_name(family_name)
      @avatar_key = avatar_key
      @favorite_year = favorite_year
    end

    def call
      raise Error.new(:name, I18n.t("errors.people.name")) if provided?(@given_name) && @given_name.blank?
      if provided?(@favorite_year) && !Person.valid_year?(@favorite_year)
        raise Error.new(:year, I18n.t("errors.people.year"))
      end
      if provided?(@avatar_key) && !Player::AVATARS.include?(@avatar_key.to_s)
        raise Error.new(:avatar, I18n.t("errors.people.avatar"))
      end

      attributes = {
        given_name: @given_name,
        family_name: provided?(@family_name) ? @family_name.presence : UNSET,
        avatar_key: @avatar_key,
        favorite_year: provided?(@favorite_year) ? @favorite_year.to_i : UNSET
      }.reject { |_key, value| value.equal?(UNSET) }
      raise Error.new(:missing, I18n.t("errors.people.missing")) if attributes.empty?

      ApplicationRecord.transaction do
        @person.update!(attributes)
        if attributes.key?(:given_name) || attributes.key?(:avatar_key)
          @person.players.find_each do |player|
            next unless player.game_session.live?

            player.update!(name: @person.given_name, avatar_key: @person.avatar_key)
          end
        end
        @person
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      raise Error.new(:taken, I18n.t("errors.people.taken_clash"))
    end

    private

      def normalize_name(value)
        return UNSET if value.equal?(UNSET)

        value.to_s.strip.first(Person::NAME_MAX)
      end

      def provided?(value)
        !value.equal?(UNSET)
      end
  end
end
