class ScoreApplier
  def self.correct!(round_run, team, broadcast: true)
    new(round_run).correct!(team, broadcast: broadcast)
  end

  def self.incorrect!(round_run, team, broadcast: true)
    new(round_run).incorrect!(team, broadcast: broadcast)
  end

  def self.adjust!(night, team, points:, reason:, broadcast: true)
    ScoreEvent.award!(
      game_session: night,
      team: team,
      kind: "adjust",
      points: points,
      xp: [ points, 0 ].max,
      reason: reason
    )
    night.broadcast_state if broadcast
  end

  def initialize(round_run)
    @round_run = round_run
    @night = round_run.game_session
    @definition = round_run.definition
  end

  def correct!(team, broadcast: true)
    return if @round_run.score_events.exists?(team: team, kind: "correct")

    multiplier = team.next_correct_doubled? ? 2 : 1
    team.update!(next_correct_doubled: false) if multiplier > 1
    points = @definition.points * multiplier
    xp = (@definition.reward["xp"] || 20) * multiplier

    ScoreEvent.award!(
      game_session: @night,
      team: team,
      round_run: @round_run,
      kind: "correct",
      points: points,
      xp: xp,
      reason: multiplier > 1 ? "Correcta con corona ×2" : "Respuesta correcta"
    )

    if @round_run.first_buzz&.team_id == team.id
      ScoreEvent.award!(
        game_session: @night,
        team: team,
        round_run: @round_run,
        kind: "fastest_buzz",
        points: 5,
        xp: 8,
        reason: "Primer buzz"
      )
    end

    team.update!(streak: team.streak + 1)
    team.recalculate_progress!
    @night.broadcast_state if broadcast
  end

  def incorrect!(team, broadcast: true)
    return if @round_run.score_events.exists?(team: team, kind: "incorrect")

    ScoreEvent.award!(
      game_session: @night,
      team: team,
      round_run: @round_run,
      kind: "incorrect",
      points: 0,
      xp: 2,
      reason: "Participó"
    )
    team.update!(streak: 0)
    team.recalculate_progress!
    @night.broadcast_state if broadcast
  end
end
