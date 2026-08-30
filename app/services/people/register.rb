module People
  class Register
    def self.call(ward: nil, given_name:, family_name: nil, avatar_key: nil, favorite_year: nil, device_token:, last_ward_team: nil)
      new(
        ward:, given_name:, family_name:, avatar_key:, favorite_year:, device_token:, last_ward_team:
      ).call
    end

    def initialize(ward:, given_name:, family_name:, avatar_key:, favorite_year:, device_token:, last_ward_team:)
      @ward = ward
      @given_name = given_name.to_s.strip.first(Person::NAME_MAX)
      @family_name = family_name.to_s.strip.first(Person::NAME_MAX)
      @avatar_key = avatar_key.presence || Player::AVATARS.sample
      @favorite_year = favorite_year
      @device_token = device_token
      @last_ward_team = last_ward_team
    end

    def call
      raise Error.new(:name, I18n.t("errors.people.name")) if @given_name.blank?
      raise Error.new(:avatar, I18n.t("errors.people.avatar")) unless Player::AVATARS.include?(@avatar_key.to_s)
      if @favorite_year.present? && !Person.valid_year?(@favorite_year)
        raise Error.new(:year, I18n.t("errors.people.year"))
      end

      ApplicationRecord.transaction do
        person = Person.create!(
          ward: @ward,
          given_name: @given_name,
          family_name: @family_name.presence,
          avatar_key: @avatar_key,
          favorite_year: @favorite_year.presence&.to_i,
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
