module Wards
  class ParseLocator
    SKIP_TYPES = %w[
      temple office storehouse institute seminary mission cannery
      visitors familyhistory family_history bishops bishop
      stake district
    ].freeze

    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload
    end

    def call
      locations.flat_map { |location| units_for(location) }
    end

    private

      def locations
        raw = @payload
        raw = JSON.parse(raw) if raw.is_a?(String)
        case raw
        when Array then raw
        when Hash
          raw["locations"] || raw["features"] || raw["results"] || raw["data"] || [ raw ]
        else
          []
        end
      end

      def units_for(location)
        loc = unwrap(location)
        assigned = Array(dig(loc, "properties", "Assigned") || loc["assigned"] || loc["units"] || loc["congregations"])
        stake = stake_name_from(loc, assigned)
        chapel = chapel_attrs(loc)

        assigned.filter_map do |item|
          unit = unwrap(item)
          kind = unit_kind_for(unit)
          next unless kind

          id = (unit["id"] || unit["unitId"] || unit["assignment_id"]).to_s.presence
          name = (unit["name"] || unit["assignment_name"] || unit["label"]).to_s.strip.presence
          next if name.blank?

          chapel.merge(
            church_unit_id: id,
            name: name.first(Ward::NAME_MAX),
            unit_kind: kind,
            stake_name: (unit["stake"] || unit["stakeName"] || unit["parentName"] || stake).to_s.strip.first(80).presence
          )
        end
      end

      def chapel_attrs(loc)
        address = unwrap(loc["address"] || loc["properties"] || {})
        coords = coordinates(loc)
        country_code = (address["countryCode2"] || address["country_code_2_digit"] || address["countryCode"] || loc["countryCode"] || loc["country_code"]).to_s.upcase.first(2).presence
        country_code = nil unless country_code.to_s.match?(/\A[A-Z]{2}\z/)

        {
          chapel_name: (loc["name"] || loc["chapelName"] || address["name"]).to_s.strip.first(80).presence,
          chapel_address: (address["street"] || address["address_line_1"] || loc["addressFormatted"] || loc["full_address"]).to_s.strip.first(80).presence,
          city: (address["city"] || loc["city"]).to_s.strip.first(80).presence,
          region: (address["state"] || address["stateCode"] || address["county"] || loc["region"]).to_s.strip.first(80).presence,
          postal_code: (address["zip"] || address["postalCode"] || loc["postal_code"]).to_s.strip.first(80).presence,
          country_code: country_code,
          country_name: (address["country"] || loc["country"]).to_s.strip.first(80).presence,
          latitude: coords[:lat],
          longitude: coords[:lng]
        }
      end

      def coordinates(loc)
        lat = loc["latitude"] || loc.dig("properties", "latitude")
        lng = loc["longitude"] || loc.dig("properties", "longitude")
        return { lat: lat.to_f, lng: lng.to_f } if lat.present? && lng.present?

        pair = loc["coordinates"] || loc.dig("geometry", "coordinates")
        if pair.is_a?(Array) && pair.size >= 2
          return { lng: pair[0].to_f, lat: pair[1].to_f }
        end

        { lat: nil, lng: nil }
      end

      def stake_name_from(loc, assigned)
        named = loc["stake"] || loc["stakeName"] || loc.dig("properties", "Stake")
        return named.to_s.strip if named.present?

        stake = assigned.map { |item| unwrap(item) }.find { |unit| stake_like?(unit_type(unit)) }
        (stake && (stake["name"] || stake["assignment_name"])).to_s.strip.presence
      end

      def unit_kind_for(unit)
        type = unit_type(unit)
        return if type.present? && SKIP_TYPES.any? { |skip| type.include?(skip) }
        return "branch" if type.include?("branch") || type.include?("rama")
        return "ward" if type.blank? || type.include?("ward") || type.include?("barrio") || type.include?("ala")

        nil
      end

      def unit_type(unit)
        (unit["type"] || unit["assignment_type"] || unit["unitType"] || "").to_s.downcase.gsub(/[\s_-]/, "")
      end

      def stake_like?(type)
        type.include?("stake") || type.include?("district") || type.include?("estaca")
      end

      def unwrap(value)
        return value["properties"].merge(value.except("properties")) if value.is_a?(Hash) && value["properties"].is_a?(Hash) && value["type"] == "Feature"

        value.is_a?(Hash) ? value : {}
      end

      def dig(hash, *keys)
        keys.reduce(hash) { |memo, key| memo.is_a?(Hash) ? memo[key] : nil }
      end
    end
end
