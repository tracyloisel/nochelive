module ApplicationHelper
  def night_title(night)
    night.theme_title
  end

  def night_poster_src(night_or_theme)
    file_id = night_or_theme.respond_to?(:theme_file_id) ? night_or_theme.theme_file_id : night_or_theme.to_s
    file_id = "reyes_y_profetas" if file_id.blank? || file_id == "kings_and_prophets"
    rel = "media/nights/#{file_id}.jpg"
    "/#{rel}" if Rails.public_path.join(rel).file?
  end

  def night_still_src(night = nil)
    if night.is_a?(GameSession)
      round = night.current_round_run
      round ||= Array(night.round_runs).max_by { |run| run.position.to_i }
      src = challenge_story(round) if round
      return src if src.present?
      return night_poster_src(night)
    end

    night_poster_src(night.presence || "reyes_y_profetas")
  end

  def story_reel(**kwargs, &block)
    render "shared/reel", **kwargs, body: capture(&block)
  end

  def night_status_caption(night)
    case night.status
    when "playing" then "En juego"
    when "lobby" then "En el vestíbulo"
    when "paused" then "En pausa"
    else "Terminada"
    end
  end

  def band_label(position)
    case position
    when 1..3 then "Descubrimiento"
    when 4..6 then "Competencia"
    when 7..10 then "Fuego"
    when 11..13 then "Caos"
    when 14 then "Semifinal"
    else "Gran final"
    end
  end

  def round_prompt(round)
    definition = round.definition
    definition.question.presence || definition.instructions
  end

  def stage_sfx(round, extra = nil, team: nil, night: nil)
    return extra if extra.present?
    return "level_up" if team&.pending_rank_up.present?
    return "royal_fanfare" if night&.finished?
    return unless round

    definition = round.definition
    if definition.layered_finale? && round.intro?
      return "dramatic_fire" if round.layer_index.to_i.zero? || round.last_layer?

      return
    end

    case round.phase
    when "intro" then definition.sfx["intro"].presence || "question_change"
    end
  end

  def stage_sfx_token(round, sfx = nil, extra = nil, team: nil, night: nil)
    [ sfx, extra, team&.pending_rank_up, night&.id, night&.status, round&.id, round&.phase, round&.try(:layer_index) ].compact.join(":")
  end

  def stage_bed(round, night: nil)
    return if night&.finished?
    return unless round&.timed? && round.seconds_left.positive?

    "timer_tension"
  end

  def stage_audio_data(round, extra_sfx = nil, extra_fx = nil, team: nil, night: nil)
    sfx = stage_sfx(round, extra_sfx, team: team, night: night)
    timed = round&.timed?
    {
      stage_sfx_value: sfx,
      stage_sfx_token_value: stage_sfx_token(round, sfx, extra_sfx, team: team, night: night),
      stage_fx_value: stage_fx(round, extra_fx, team: team, night: night),
      stage_bed_value: stage_bed(round, night: night),
      stage_timer_end_value: timed && round.ends_at ? round.ends_at.iso8601 : nil,
      stage_timer_duration_value: timed ? round.definition.duration.to_i : nil
    }
  end

  def stage_fx(round, extra = nil, team: nil, night: nil)
    return extra if extra.present?
    return "level" if team&.pending_rank_up.present?
    return "finale" if night&.finished?
    return "shake" if round&.locked? && round.definition.freeze?

    round&.revealed? ? "reveal" : nil
  end

  def medal_label(position)
    { 1 => "1.º", 2 => "2.º", 3 => "3.º" }[position] || "#{position}.º"
  end

  def latency_label(ms)
    return if ms.blank?

    "#{ms.to_i} ms"
  end

  def team_roster(team)
    Array(team&.players).select(&:participant?).map(&:name).reject(&:blank?)
  end

  def roster_line(team)
    names = team_roster(team)
    return if names.empty?
    return names.first if names.size == 1

    "#{names[0..-2].join(", ")} y #{names.last}"
  end

  def missionary_line(night)
    names = Array(night&.missionaries).map(&:name).reject(&:blank?)
    return if names.empty?
    return names.first if names.size == 1

    "#{names[0..-2].join(", ")} y #{names.last}"
  end

  def finale_blessing
    "La corona se queda en esta casa."
  end

  def vote_tally_line(round)
    counts = round.ballots.group(:choice_team_id).count
    return if counts.empty?

    top = counts.values.max
    names = Team.where(id: counts.select { |_id, votes| votes == top }.keys).order(:name).pluck(:name)
    return if names.empty?
    return "¡#{names.first} tiene la sabiduría!" if names.size == 1

    "¡#{names.join(" y ")} comparten la sabiduría!"
  end

  def rank_up_shout(team)
    return if team.pending_rank_up.blank?
    return "¡#{team.name} es #{team.pending_rank_up} y Rey!" if team.rey?

    "¡#{team.name} es #{team.pending_rank_up}!"
  end

  def night_leader_line(night)
    champs = night.first_place_teams
    return if champs.empty?
    return "#{champs.map(&:name).join(" y ")} van juntos." if night.tied_finale?

    "#{night.champion.name} va delante."
  end

  def player_remote?(player)
    player&.remote?
  end

  def phone_quiz?(round, player)
    definition = round&.definition
    return false unless definition
    return false if definition.layered_finale?
    return true if definition.choice?

    player_remote?(player) && definition.buzzer? && definition.has_choices?
  end

  def phone_quiz_asking?(round, player)
    return false unless round
    return round.open? if round.definition.choice?

    phone_quiz?(round, player) && round.phase.in?(%w[open locked answering])
  end

  def team_explainer(team)
    return if team&.solo?

    team.players.min_by(&:id)
  end

  def explainer?(team, player)
    return false if team&.solo? && player_remote?(player)

    player && team_explainer(team)&.id == player.id
  end

  def mark_src(kind, key)
    return if key.blank?

    rel = "marks/#{kind}/#{key}.jpg"
    "/#{rel}" if Rails.public_path.join(rel).file?
  end

  def emblem_mark(key)
    mark_src("emblems", key)
  end

  def icon_mark(key)
    mark_src("icons", key)
  end

  def avatar_mark(record)
    key = record.is_a?(String) ? record : record&.avatar_key
    mark_src("avatars", key)
  end

  def player_label(player, peers = nil)
    return player.name if player.blank?

    list = peers || player.game_session.players
    dupes = Array(list).count { |row| row.name.to_s.casecmp?(player.name.to_s) } > 1
    return player.name unless dupes

    extra = player.person&.family_name
    extra.present? ? "#{player.name} #{extra}" : player.name
  end

  def challenge_media_id(round)
    round&.definition&.id
  end

  def challenge_clip(round)
    layered = burger_clip(round)
    return layered if layered

    id = challenge_media_id(round)
    return unless id

    rel = "media/challenges/#{id}/clip.mp4"
    rel if Rails.public_path.join(rel).file?
  end

  def challenge_story(round)
    definition = round&.definition
    return unless definition

    if (layer = burger_layer_for(round))
      src = media_src(layer["image"])
      return src if src
    end

    yaml_rel = definition.presentation&.[]("image").presence
    if yaml_rel
      src = media_src(yaml_rel)
      return src if src
    end

    id = definition.id
    %w[jpg jpeg png webp].each do |ext|
      rel = "media/stories/#{id}.#{ext}"
      return "/#{rel}" if Rails.public_path.join(rel).file?
    end
    nil
  end

  def burger_layer_for(round)
    definition = round&.definition
    return unless definition&.layered_finale?

    round.current_layer || definition.layers.find { |layer| layer["key"] == "chariot" } || definition.layers[2]
  end

  def burger_clip(round)
    layer = burger_layer_for(round)
    rel = media_public_path(layer&.[]("clip"))
    rel
  end

  def media_public_path(rel)
    return if rel.blank?

    rel = rel.to_s.delete_prefix("/")
    rel = "media/#{rel}" unless rel.start_with?("media/")
    rel if Rails.public_path.join(rel).file?
  end

  def media_src(rel)
    path = media_public_path(rel)
    "/#{path}" if path
  end

  def burger_stakes_line(night, you = nil)
    scores = Team.where(game_session_id: night.id).pluck(:cached_score)
    return "El burger puede cambiar el marcador." if you.nil?

    best = scores.max || 0
    tied = scores.count { |score| score == best } > 1
    me = you.cached_score.to_i
    return "Van juntos. El burger deshace el empate." if tied && me == best
    return "Podéis cerrar la noche." if me == best

    "Si acertáis, pasáis delante."
  end

  def burger_host_value_line(night, round)
    team = round.answering_team
    if team.nil? && round.finale_steal_open?
      remote_teams = night.teams.select { |row| row.players.any? { |player| player.participant? && player.remote? } }
      team = remote_teams.first if remote_teams.size == 1
    end
    points = team ? round.definition.swing_points(night, team) : round.definition.points
    "Esta respuesta vale #{points}."
  end

  def burger_watch_steal_line(night)
    casa = night.teams.select { |team| team.players.any? { |player| player.participant? && player.remote? } }
    casa.size == 1 ? "Casa puede robar la noche." : "Pueden robar la noche."
  end

  def burger_garnish_kind(round)
    return unless round&.definition&.layered_finale?
    return "nugget" if round.finale_steal_open?
    return "fry" if round.anyone_correct?

    index = round.layer_index.to_i
    return "fry" if index <= 0 || round.last_layer? || round.phase.in?(%w[open locked answering])
    return "lettuce" if index <= 2

    "nugget"
  end

  def burger_garnish_count(round, cinema: false)
    kind = burger_garnish_kind(round)
    return 0 unless kind

    index = round.layer_index.to_i
    heavy = if round.finale_steal_open?
      28
    elsif kind == "lettuce" && index == 2
      24
    elsif kind == "lettuce"
      8
    elsif index <= 0
      8
    else
      18
    end
    cinema ? heavy : [ (heavy / 3.0).ceil, 4 ].max
  end

  def chapel_players(night)
    night.players.participants.where(location: "room").includes(:team).order(:id).to_a
  end

  def burger_cheer_targets(night)
    faces = chapel_players(night)
    return { mode: :empty, faces: [], teams: [] } if faces.empty?
    return { mode: :emblems, faces: [], teams: chapel_cheer_teams(night, faces) } if faces.size >= 9

    { mode: :faces, faces: faces, teams: [] }
  end

  def chapel_cheer_teams(night, faces)
    ids = faces.map(&:team_id).uniq
    night.teams.includes(:players).where(id: ids).order(:name)
  end

  def cheer_to_you_line(names)
    names = Array(names).map(&:to_s).reject(&:blank?).uniq
    return if names.empty?
    return "¡#{names.first} te anima!" if names.size == 1

    "¡#{names[0..-2].join(", ")} y #{names.last} te animan!"
  end

  def layer_cheers(round)
    return Cheer.none unless round

    round.cheers.where(layer_index: round.layer_index).includes(:player, :to_player)
  end

  def challenge_slides(round)
    id = challenge_media_id(round)
    return [] unless id

    dir = Rails.public_path.join("media/challenges/#{id}/slides")
    return [] unless dir.directory?

    dir.children.select { |path| path.file? && path.extname.downcase.in?(%w[.jpg .jpeg .png .webp]) }
       .sort
       .map { |path| "/media/challenges/#{id}/slides/#{path.basename}" }
  end

  CHOICE_MARKS = [
    { shape: "circle", tone: "gold" },
    { shape: "square", tone: "fire" },
    { shape: "triangle", tone: "navy" },
    { shape: "star", tone: "deep" }
  ].freeze

  def picto(name, size: nil)
    render "shared/picto", name: name.to_s, size: size
  end

  def choice_mark(index)
    CHOICE_MARKS[index.to_i % CHOICE_MARKS.size]
  end

  def choice_key(choice)
    if choice.is_a?(Hash)
      (choice["key"] || choice[:key] || choice["label"] || choice[:label]).to_s
    else
      choice.to_s
    end
  end

  def choice_label(choice)
    if choice.is_a?(Hash)
      (choice["label"] || choice[:label] || choice["key"] || choice[:key]).to_s
    else
      choice.to_s
    end
  end

  def answer_body_label(round, answer)
    definition = round.definition
    if definition.ordering?
      definition.order_labels(answer.body).join(" → ")
    elsif definition.mime? && definition.story_path?
      definition.path_labels(answer.body).join(" → ")
    elsif definition.freeze?
      "#{answer.body.to_i} ms"
    elsif Array(definition.choices).any?
      row = Array(definition.choices).find { |choice| choice_key(choice) == answer.body.to_s }
      row ? choice_label(row) : answer.body
    else
      answer.body
    end
  end
end
