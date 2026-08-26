module Platform
  class Pulse
    Result = Struct.new(:players, :questions, :online, keyword_init: true)

    def self.call
      new.call
    end

    def call
      range = Time.current.all_month
      Result.new(
        players: monthly_players(range),
        questions: QuizAnswer.where(created_at: range).count,
        online: live_count
      )
    end

    private

      def monthly_players(range)
        month = QuizAnswer.joins(:quiz_run).where(quiz_answers: { created_at: range })
        fichas = month.where.not(quiz_runs: { person_id: nil }).distinct.count("quiz_runs.person_id")
        guests = month.where(quiz_runs: { person_id: nil }).distinct.count("quiz_answers.device_digest")
        fichas + guests
      end

      def live_count
        street = PersonDevice.live.distinct.pluck(:person_id)
        night = Player.live.where.not(person_id: nil).distinct.pluck(:person_id)
        guests = Player.live.where(person_id: nil).count
        (street | night).size + guests
      end
  end
end
