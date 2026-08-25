module Quizzes
  class Complete
    Summary = Struct.new(:score, :average, :n, :first, :standings, :pack_board, :total_board, keyword_init: true)

    def self.call(run:)
      raise "Not done" unless run.open? && run.last_question? && run.settled?

      run.update!(status: "finished", ends_at: nil)
      run
    end

    def self.summary(run, ward: nil, person: nil)
      finished = QuizRun.where(pack_id: run.pack_id, status: "finished")
      n = finished.count
      average = n >= 2 ? finished.average(:score).to_f.round : nil
      ward ||= person&.ward
      standings = ward && person ? Standings.call(ward:, person:, pack_id: run.pack_id) : nil
      Summary.new(
        score: run.score.to_i,
        average:,
        n:,
        first: n < 2,
        standings:,
        pack_board: standings&.pack_board,
        total_board: standings&.total_board
      )
    end
  end
end
