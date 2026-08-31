module Nights
  class Projection
    TeamRow = Data.define(:id, :name, :emblem, :score, :players)
    QuestionRow = Data.define(:id, :pack_title, :label, :answered, :eligible, :percent)
    Result = Data.define(:teams, :questions, :events, :registered)

    def self.registration(night:)
      Result.new([], [], [], night.players.count)
    end

    def self.call(night:)
      registered = night.players.count
      scores = night.quiz_runs.group(:team_id).sum(:score)
      team_records = night.teams.order(:name).to_a
      counts = TeamMembership.where(team_id: team_records.map(&:id)).group(:team_id).count
      teams = team_records.map do |team|
        TeamRow.new(team.id, team.name, team.emblem, scores[team.id].to_i, counts[team.id].to_i)
      end.sort_by { |row| [ -row.score, -row.players, row.name ] }

      answered = QuizAnswer.joins(:quiz_run)
        .where(quiz_runs: { game_session_id: night.id })
        .group("quiz_runs.pack_id", :question_id)
        .count
      eligible = night.quiz_runs.group(:pack_id).distinct.count(:player_id)
      packs = night.quiz_packs
      questions = packs.each_with_index.flat_map do |pack, pack_index|
        pack.questions.map do |question|
          total = eligible[pack.id].to_i
          done = answered[[ pack.id, question.id ]].to_i
          label = packs.one? ? "Q#{question.position}" : "Q#{pack_index + 1}.#{question.position}"
          QuestionRow.new(question.id, pack.copy(:title), label, done, total, total.positive? ? ((done * 100.0) / total).round : 0)
        end
      end

      Result.new(teams, questions, night.live_events.recent_first.limit(24).to_a, registered)
    end
  end
end
