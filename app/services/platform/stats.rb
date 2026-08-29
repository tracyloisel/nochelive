module Platform
  class Stats
    WORLD_LIMIT = 20

    Lang = Struct.new(:code, :count, :share, keyword_init: true)
    WorldRow = Struct.new(:rank, :person, :ward, :score, keyword_init: true)
    Result = Struct.new(
      :people, :wards, :countries, :languages,
      :answers, :correct, :wrong, :path_share,
      :duels, :nights, :teams,
      :invitations_sent, :invitations_opened, :friends_joined, :invitation_duels_completed, :invitation_share,
      :world,
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

      invitation_stats = invitation_stats()
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
        invitations_sent: invitation_stats[:sent],
        invitations_opened: invitation_stats[:opened],
        friends_joined: invitation_stats[:joined],
        invitation_duels_completed: invitation_stats[:completed],
        invitation_share: invitation_stats[:sent].positive? ? invitation_stats[:joined].to_f / invitation_stats[:sent] : 0.0,
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

      def invitation_stats
        shared_ids = ViralEvent.where(name: "invite_share_handoff")
          .where.not(duel_invitation_id: nil)
          .distinct
          .select(:duel_invitation_id)
        shared = DuelInvitation.where(id: shared_ids)
        {
          sent: shared.count,
          opened: ViralEvent.where(name: "invite_human_opened", duel_invitation_id: shared_ids)
            .distinct.count(:duel_invitation_id),
          joined: shared.where(status: "claimed").count,
          completed: StreetDuel.where(origin_invitation_id: shared_ids, status: "resolved").count
        }
      end

      def world_rows
        ordered = Quizzes::Leaderboard.pack_best_totals.sort_by { |_, score| -score }.first(WORLD_LIMIT)
        people_by_id = Person.includes(:ward).where(id: ordered.map(&:first)).index_by(&:id)
        ranked = ordered.filter_map do |person_id, score|
          person = people_by_id[person_id]
          next unless person&.ward

          [ person, score ]
        end

        ranked.each_with_index.map do |(person, score), index|
          ward = person.ward
          WorldRow.new(
            rank: index + 1,
            person:,
            ward:,
            score:
          )
        end
      end
  end
end
