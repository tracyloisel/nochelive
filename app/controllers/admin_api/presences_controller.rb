module AdminApi
  class PresencesController < BaseController
    LIMIT = 500

    def index
      zone = ActiveSupport::TimeZone[params[:timezone].presence || "Europe/Madrid"]
      return render json: { error: "Unknown timezone" }, status: :unprocessable_entity unless zone

      date = params[:date].present? ? Date.iso8601(params[:date]) : zone.today
      range = zone.local(date.year, date.month, date.day).all_day
      people = people_seen(range)
      people = filter_country(people)
      people = filter_ward(people)
      total = people.count
      rows = people.includes(:ward, :person_devices, :players).limit(LIMIT).map do |person|
        seen_at = (person.person_devices.map(&:last_seen_at) + person.players.map(&:last_seen_at)).compact.max
        {
          id: person.id,
          name: person.display_name,
          ward_code: person.ward&.code,
          ward_name: person.ward&.name,
          country_code: person.ward&.country_code,
          last_seen_at: seen_at&.iso8601
        }
      end.sort_by { |row| row[:last_seen_at].to_s }.reverse

      render json: {
        date: date.iso8601,
        timezone: zone.tzinfo.name,
        scope: { country: params[:country].presence, ward_code: params[:ward_code].presence },
        count: total,
        truncated: total > LIMIT,
        people: rows
      }
    rescue Date::Error
      render json: { error: "Date must use YYYY-MM-DD" }, status: :unprocessable_entity
    end

    private

      def people_seen(range)
        device_ids = PersonDevice.where(last_seen_at: range).select(:person_id)
        player_ids = Player.where(last_seen_at: range).where.not(person_id: nil).select(:person_id)
        Person.where(id: device_ids).or(Person.where(id: player_ids))
      end

      def filter_country(scope)
        return scope unless params[:country].present?

        query = params[:country].to_s.strip
        scope.joins(:ward).where(
          "UPPER(wards.country_code) = :code OR wards.country_name ILIKE :name",
          code: query.upcase,
          name: query
        )
      end

      def filter_ward(scope)
        return scope unless params[:ward_code].present?

        scope.joins(:ward).where(wards: { code: Ward.normalize_code(params[:ward_code]) })
      end
  end
end
