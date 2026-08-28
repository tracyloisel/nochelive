class Sfx
  require "digest"

  CUES = %w[
    round_start
    buzzer_hit
    correct_gold
    wrong_soft
    score_transfer
    crown_chime
    royal_fanfare
    level_up
    chest
    dramatic_fire
    fire_whoosh
    flame_gold
    timer_tension
    tick
    tick_low
    round_open
    round_lock
    question_change
    celestial_breath
    duel_send
    stake_gain
    reveal
    study_refuge
    study_light
    study_miss
    study_turn
  ].freeze

  PULSE = {
    "join" => "chest",
    "pose" => "chest",
    "open" => "round_open",
    "advance" => "question_change",
    "lock" => "round_lock",
    "freeze" => "dramatic_fire",
    "reveal" => "reveal",
    "score" => "correct_gold",
    "miss" => "wrong_soft",
    "cheer" => "chest",
    "buzz" => "buzzer_hit",
    "found" => "buzzer_hit",
    "shout" => "buzzer_hit",
    "answer" => "buzzer_hit"
  }.freeze

  PULSE_YAML = {
    "open" => "intro",
    "lock" => "lock",
    "freeze" => "lock",
    "score" => "correct",
    "miss" => "wrong",
    "buzz" => "buzz",
    "found" => "buzz",
    "shout" => "buzz",
    "answer" => "buzz"
  }.freeze

  PULSE_SOLO = %w[lock reveal score open advance miss].freeze

  def self.catalog
    CUES.index_with { |name| versioned_path_for(name) }.compact
  end

  def self.known?(name)
    CUES.include?(name.to_s)
  end

  def self.file_for(name)
    return unless known?(name)

    file = Rails.public_path.join("sfx/#{name}.mp3")
    file if file.file?
  end

  def self.path_for(name)
    file = file_for(name)
    "/sfx/#{file.basename}" if file
  end

  def self.versioned_path_for(name)
    file = file_for(name)
    return unless file

    "#{path_for(name)}?v=#{Digest::SHA256.file(file).hexdigest[0, 12]}"
  end

  def self.for_pulse(kind, source = nil)
    kind = kind.to_s
    round = source if source.respond_to?(:yaml_round_id)
    definition = round ? round.definition : source
    if kind == "open" && round&.definition&.layered_finale? && !round.intro?
      return PULSE.fetch("open")
    end

    yaml_key = PULSE_YAML[kind]
    override = definition&.sfx&.[](yaml_key).presence
    return override if override && known?(override)

    PULSE.fetch(kind, "buzzer_hit")
  end

  def self.for_grade(definition, correct:)
    key = correct ? "correct" : "wrong"
    override = definition&.sfx&.[](key).presence
    return override if override && known?(override)

    correct ? "correct_gold" : "wrong_soft"
  end

  def self.pulse_without_player?(kind)
    PULSE_SOLO.include?(kind.to_s)
  end
end
