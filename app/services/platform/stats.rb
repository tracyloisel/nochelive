module Platform
  class Stats
    WORLD_LIMIT = 20

    Lang = Struct.new(:code, :count, :share, keyword_init: true)
    WorldRow = Struct.new(:rank, :person, :ward_name, :country, :score, keyword_init: true)
    Result = Struct.new(
      :people, :wards, :countries, :languages,
      :answers, :correct, :wrong, :path_share,
      :duels, :nights, :teams, :world,
      keyword_init: true
    )

    def self.call
      new.call
    end

    def call
      people = Person.count
      ward_ids = Person.distinct.pluck(:ward_id)
      answers = QuizAnswer.count
      correct = QuizAnswer.where(correct: true).count

      Result.new(
        people:,
        wards: ward_ids.size,
        countries: country_count(ward_ids),
        languages: language_rows(people),
        answers:,
        correct:,
        wrong: answers - correct,
        path_share: answers.positive? ? correct.to_f / answers : 0.0,
        duels: StreetDuel.count,
        nights: GameSession.count,
        teams: Team.chapel.count,
        world: world_rows
      )
    end

    private

      def country_count(ward_ids)
        return 0 if ward_ids.empty?

        Ward.where(id: ward_ids).where.not(country_code: [ nil, "" ]).distinct.count(:country_code)
      end

      def language_rows(people)
        counts = Person.group(:locale).count
        Locale::AVAILABLE.map do |code|
          count = counts[code].to_i
          Lang.new(code:, count:, share: people.positive? ? count.to_f / people : 0.0)
        end
      end

      def world_rows
        ordered = Quizzes::Leaderboard.pack_best_totals.sort_by { |_, score| -score }.first(WORLD_LIMIT)
        people_by_id = Person.includes(:ward).where(id: ordered.map(&:first)).index_by(&:id)
        ordered.each_with_index.filter_map do |(person_id, score), index|
          person = people_by_id[person_id]
          next unless person

          ward = person.ward
          WorldRow.new(
            rank: index + 1,
            person:,
            ward_name: ward.name,
            country: ward.country_name.presence || ward.country_code,
            score:
          )
        end
      end
  end
end
