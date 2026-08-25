module Wards
  class Search
    FEATURED_LIMIT = 6
    QUERY_LIMIT = 24
    MIN_QUERY = 2

    def self.call(query:, limit: nil)
      new(query:, limit:).call
    end

    def initialize(query:, limit: nil)
      @query = query.to_s.strip
      @limit = limit
    end

    def call
      if @query.length < MIN_QUERY
        featured
      else
        matching
      end
    end

    private

      def featured
        directory.order(featured_sql, updated_at: :desc).limit(@limit || FEATURED_LIMIT).to_a
      end

      def matching
        limit = @limit || QUERY_LIMIT
        code = Ward.normalize_code(@query)
        pattern = "%#{Ward.sanitize_sql_like(@query)}%"
        rows = directory.where(
          "name ILIKE :q OR city ILIKE :q OR chapel_name ILIKE :q OR chapel_address ILIKE :q OR region ILIKE :q OR country_code ILIKE :q OR code ILIKE :q",
          q: pattern
        ).order(updated_at: :desc).limit(limit).to_a

        exact = code.present? ? directory.find_by(code: code) : nil
        if exact
          ([ exact ] + rows.reject { |ward| ward.id == exact.id }).first(limit)
        else
          rows
        end
      end

      def directory
        Ward.listed.includes(:game_sessions)
      end

      def featured_sql
        Arel.sql("CASE WHEN LOWER(COALESCE(city, '')) = #{Ward.connection.quote(Ward::FEATURED_CITY)} OR code = #{Ward.connection.quote(Ward::FEATURED_CODE)} THEN 0 ELSE 1 END")
      end
  end
end
