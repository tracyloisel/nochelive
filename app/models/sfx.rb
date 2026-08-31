class Sfx
  require "digest"

  CUES = %w[
    round_start
    correct_gold
    notification_glint
    wrong_soft
    street_wrong_soft
    score_transfer
    crown_chime
    royal_fanfare
    street_royal_fanfare
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

  def self.catalog
    @catalog ||= CUES.index_with { |name| build_versioned_path_for(name) }.compact.freeze
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
    catalog[name.to_s]
  end

  def self.build_versioned_path_for(name)
    file = file_for(name)
    return unless file

    "#{path_for(name)}?v=#{Digest::SHA256.file(file).hexdigest[0, 12]}"
  end
  private_class_method :build_versioned_path_for

end
