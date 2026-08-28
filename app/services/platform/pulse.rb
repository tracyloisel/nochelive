module Platform
  class Pulse
    CACHE_TTL = 5.minutes
    Result = Struct.new(:players, :questions, :online, :wards, keyword_init: true)

    def self.call
      new.call
    end

    def call
      range = Time.current.all_month
      questions, players = monthly_totals(range)
      Result.new(
        players:,
        questions:,
        online: live_count,
        wards: Rails.cache.fetch("platform/pulse/wards", expires_in: CACHE_TTL) { Ward.listed.count }
      )
    end

    private

      def monthly_totals(range)
        Rails.cache.fetch("platform/pulse/month/#{range.first.to_date}", expires_in: CACHE_TTL) do
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
      end

      def live_count
        Presences::Registry.live_count
      end
  end
end
