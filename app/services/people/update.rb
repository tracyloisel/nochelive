module People
  class Update
    def self.call(person:, given_name:, family_name:, avatar_key:, favorite_year:)
      new(person:, given_name:, family_name:, avatar_key:, favorite_year:).call
    end

    def initialize(person:, given_name:, family_name:, avatar_key:, favorite_year:)
      @person = person
      @given_name = given_name.to_s.strip.first(24)
      @family_name = family_name.to_s.strip.first(24)
      @avatar_key = avatar_key
      @favorite_year = favorite_year
    end

    def call
      raise Error.new(:name, I18n.t("errors.people.name")) if @given_name.blank?
      raise Error.new(:year, I18n.t("errors.people.year")) unless Person.valid_year?(@favorite_year)
      raise Error.new(:avatar, I18n.t("errors.people.avatar")) unless Player::AVATARS.include?(@avatar_key.to_s)

      ApplicationRecord.transaction do
        @person.update!(
          given_name: @given_name,
          family_name: @family_name.presence,
          avatar_key: @avatar_key,
          favorite_year: @favorite_year.to_i
        )
        @person.players.find_each do |player|
          next unless player.game_session.live?

          player.update!(name: @person.given_name, avatar_key: @person.avatar_key)
        end
        @person
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      raise Error.new(:taken, I18n.t("errors.people.taken_clash"))
    end
  end
end
