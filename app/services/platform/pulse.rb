module Platform
  class Pulse
    CACHE_TTL = 15.seconds
    Result = Struct.new(:players, :questions, :online, keyword_init: true)

    def self.call
      Rails.cache.fetch("platform/pulse/v2", expires_in: CACHE_TTL) { new.call }
    end

    def call
      range = Time.current.all_month
      questions, players = monthly_totals(range)
      Result.new(
        players:,
        questions:,
        online: live_count
      )
    end

    private

      def monthly_totals(range)
        month = QuizAnswer.joins(:quiz_run).where(quiz_answers: { created_at: range })
        identity = <<~SQL.squish
          CASE
            WHEN quiz_runs.person_id IS NOT NULL THEN 'person:' || quiz_runs.person_id::text
            ELSE 'device:' || quiz_answers.device_digest
          END
        SQL
        questions, players = month.pick(
          Arel.sql("COUNT(*)"),
          Arel.sql("COUNT(DISTINCT (#{identity}))")
        )
        [ questions.to_i, players.to_i ]
      end

      def live_count
        cutoff = Time.current - PersonDevice::LIVE_WINDOW
        quoted_cutoff = ActiveRecord::Base.connection.quote(cutoff)
        ActiveRecord::Base.connection.select_value(<<~SQL).to_i
          SELECT COUNT(*)
          FROM (
            SELECT 'person:' || person_id::text AS identity
            FROM person_devices
            WHERE last_seen_at >= #{quoted_cutoff}
            UNION
            SELECT CASE
              WHEN person_id IS NOT NULL THEN 'person:' || person_id::text
              ELSE 'guest:' || id::text
            END AS identity
            FROM players
            WHERE last_seen_at >= #{quoted_cutoff}
          ) live_identities
        SQL
      end
  end
end
