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
    case round.phase
    when "intro" then definition.sfx["intro"] || "round_start"
    when "open" then "round_start"
    when "locked" then definition.sfx["lock"] || (definition.freeze? ? "dramatic_fire" : nil)
    when "revealed" then definition.sfx["correct"] || "correct_gold"
    end
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

  def team_explainer(team)
    team.players.min_by(&:id)
  end

  def explainer?(team, player)
    player && team_explainer(team)&.id == player.id
  end

  def illustration_partial(key)
    return "illustrations/crown" if key.blank?
    "illustrations/#{key}"
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
    id = challenge_media_id(round)
    return unless id

    rel = "media/challenges/#{id}/clip.mp4"
    rel if Rails.public_path.join(rel).file?
  end

  def challenge_story(round)
    definition = round&.definition
    return unless definition

    yaml_rel = definition.presentation&.[]("image").presence
    if yaml_rel
      rel = yaml_rel.to_s.delete_prefix("/")
      rel = "media/#{rel}" unless rel.start_with?("media/")
      return "/#{rel}" if Rails.public_path.join(rel).file?
    end

    id = definition.id
    %w[jpg jpeg png webp].each do |ext|
      rel = "media/stories/#{id}.#{ext}"
      return "/#{rel}" if Rails.public_path.join(rel).file?
    end
    nil
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
