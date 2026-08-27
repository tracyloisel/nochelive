module Studies
  class Community
    Result = Data.define(:rows, :players, :lights)

    def self.call(ward:, week:, completed: false, offset: nil, limit: nil)
      return Result.new(rows: [], players: 0, lights: 0) unless ward && week

      scope = StudyRun.joins(:person, study_quiz_version: :study_unit)
        .where(people: { ward_id: ward.id }, study_units: { id: week.id })
      scope = scope.completed if completed
      players = scope.distinct.count(:person_id)
      rows_scope = scope
        .group("people.id", "people.given_name", "people.avatar_key")
        .select("people.id AS person_id, people.given_name, people.avatar_key, MAX(study_runs.score) AS best_score, MAX(study_runs.position) AS progress")
        .order(Arel.sql("MAX(study_runs.position) DESC, MAX(study_runs.score) DESC, people.given_name ASC, people.id ASC"))
      rows_scope = rows_scope.offset(offset) if offset
      rows_scope = rows_scope.limit(limit) if limit
      rows = rows_scope.to_a

      Result.new(rows:, players:, lights: rows.sum { |row| row.progress.to_i })
    end
  end
end
