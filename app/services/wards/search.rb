module Wards
  class Search
    QUERY_LIMIT = 8
    MIN_QUERY = 2
    Hit = Struct.new(:name, :city, :country_code, :country_name, :stake_name, :church_unit_id, :chapel_address, :suggested, keyword_init: true) do
      def persisted? = false
      def code = nil
      def featured?
        suggested || city.to_s.downcase == Ward::FEATURED_CITY || name.to_s.match?(/benidorm/i)
      end
    end

    def self.call(query: "", latitude: nil, longitude: nil, limit: nil, with_sessions: false)
      new(query:, latitude:, longitude:, limit:, with_sessions:).tap(&:load)
    end

    attr_reader :query, :wards

    def initialize(query: "", latitude: nil, longitude: nil, limit: nil, with_sessions: false)
      @query = query.to_s.strip
      @latitude = latitude
      @longitude = longitude
      @limit = limit
      @with_sessions = with_sessions
      @wards = []
    end

    def load
      if matching?
        @wards = matching
      elsif nearby_coords?
        @wards = nearby
      elsif @query.blank?
        @wards = home_listed
      else
        @wards = []
      end
      self
    end

    def matching?
      @query.length >= MIN_QUERY
    end

    def featured?
      !matching?
    end

    def nearby?
      featured? && nearby_coords?
    end

    private

      def home_listed
        ward = directory.find_by(code: Ward::FEATURED_CODE)
        ward ? [ ward ] : []
      end

      def nearby_coords?
        return false if @latitude.blank? || @longitude.blank?

        lat = @latitude.to_f
        lng = @longitude.to_f
        lat.abs <= 90 && lng.abs <= 180
      end

      def nearby
        hit = QueryLocator.near(latitude: @latitude, longitude: @longitude).first
        return [] unless hit && hit[:church_unit_id].present? && hit[:name].present?

        local = directory.find_by(church_unit_id: hit[:church_unit_id])
        local ||= directory.find_by(code: Ward::FEATURED_CODE) if same_unit?(Ward.find_by(code: Ward::FEATURED_CODE), hit)
        return [ local ] if local

        [ hit_from(hit, suggested: true) ]
      end

      def matching
        limit = @limit || QUERY_LIMIT
        merge_locator(matching_local(limit), limit)
      end

      def matching_local(limit)
        code = Ward.normalize_code(@query)
        pattern = "%#{Ward.sanitize_sql_like(@query)}%"
        rows = directory.where(
          "name ILIKE :q OR city ILIKE :q OR chapel_name ILIKE :q OR chapel_address ILIKE :q OR region ILIKE :q OR country_code ILIKE :q OR country_name ILIKE :q OR stake_name ILIKE :q OR code ILIKE :q",
          q: pattern
        ).order(updated_at: :desc).limit(limit).to_a

        exact = code.present? ? directory.find_by(code: code) : nil
        if exact
          ([ exact ] + rows.reject { |ward| ward.id == exact.id }).first(limit)
        else
          rows
        end
      end

      def merge_locator(local, limit)
        extras = QueryLocator.call(query: @query).filter_map do |hit|
          next if hit[:church_unit_id].blank? || hit[:name].blank?
          next if local.any? { |ward| same_unit?(ward, hit) }

          hit_from(hit)
        end
        (local + extras).first(limit)
      end

      def hit_from(hit, suggested: false)
        Hit.new(
          name: hit[:name],
          city: hit[:city],
          country_code: hit[:country_code],
          country_name: hit[:country_name],
          stake_name: hit[:stake_name],
          church_unit_id: hit[:church_unit_id],
          chapel_address: hit[:chapel_address],
          suggested: suggested
        )
      end

      def same_unit?(ward, hit)
        return false unless ward

        uid = hit[:church_unit_id].to_s
        return true if uid.present? && ward.church_unit_id.to_s == uid
        return true if ward.featured? && (hit[:city].to_s.downcase == Ward::FEATURED_CITY || hit[:name].to_s.match?(/benidorm/i))

        false
      end

      def directory
        rel = Ward.listed
        rel = rel.includes(:game_sessions) if @with_sessions
        rel
      end
  end
end
