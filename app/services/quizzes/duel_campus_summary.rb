module Quizzes
  class DuelCampusSummary
    Summary = Data.define(:crowns, :active, :incoming)

    def self.call(person:, campus:)
      counts = campus&.counts
      Summary.new(
        crowns: person ? Quizzes::Complete.total_best(person) : 0,
        active: counts&.active.to_i,
        incoming: counts&.incoming.to_i
      )
    end
  end
end
