module People
  class Register
    def self.call(ward:, given_name:, family_name:, avatar_key:, favorite_year:, device_token:, last_ward_team: nil)
      new(
        ward:, given_name:, family_name:, avatar_key:, favorite_year:, device_token:, last_ward_team:
      ).call
    end

    def initialize(ward:, given_name:, family_name:, avatar_key:, favorite_year:, device_token:, last_ward_team:)
      @ward = ward
      @given_name = given_name.to_s.strip.first(24)
      @family_name = family_name.to_s.strip.first(24)
      @avatar_key = avatar_key
      @favorite_year = favorite_year
      @device_token = device_token
      @last_ward_team = last_ward_team
    end

    def call
      raise Error.new(:name, I18n.t("errors.people.name")) if @given_name.blank?
      raise Error.new(:year, I18n.t("errors.people.year")) unless Person.valid_year?(@favorite_year)
      raise Error.new(:avatar, I18n.t("errors.people.avatar")) unless Player::AVATARS.include?(@avatar_key.to_s)

      homonyms = @ward.people.named(@given_name)
      if homonyms.exists? && @family_name.blank?
        raise Error.new(:family, I18n.t("errors.people.family"))
      end

      twin = homonyms.find_by(
        family_name_key: Person.name_key(@family_name),
        avatar_key: @avatar_key,
        favorite_year: @favorite_year.to_i
      )
      raise Error.new(:taken, I18n.t("errors.people.taken")) if twin

      ApplicationRecord.transaction do
        person = @ward.people.create!(
          given_name: @given_name,
          family_name: @family_name.presence,
          avatar_key: @avatar_key,
          favorite_year: @favorite_year.to_i,
          last_ward_team: @last_ward_team,
          locale: Locale.cast(I18n.locale)
        )
        attach_device!(person)
        person
      end
    rescue ActiveRecord::RecordNotUnique
      raise Error.new(:taken, I18n.t("errors.people.taken"))
    end

    private

      def attach_device!(person)
        return if @device_token.blank?

        PersonDevice.find_or_create_by!(person:, device_token: @device_token) do |row|
          row.last_seen_at = Time.current
        end
      end
  end
end
