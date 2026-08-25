class Sfx
  CUES = %w[
    round_start
    buzzer_hit
    correct_gold
    wrong_soft
    royal_fanfare
    level_up
    chest
    dramatic_fire
    fire_whoosh
    timer_tension
    tick
    tick_low
    round_open
    round_lock
    question_change
    reveal
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

  PULSE_SOLO = %w[lock reveal score open advance].freeze

  def self.catalog
    CUES.index_with { |name| path_for(name) }.compact
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

  def self.for_pulse(kind)
    PULSE.fetch(kind.to_s, "buzzer_hit")
  end

  def self.pulse_without_player?(kind)
    PULSE_SOLO.include?(kind.to_s)
  end
end
