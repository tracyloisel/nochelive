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
  ].freeze

  def self.catalog
    CUES.index_with { |name| "/sfx/#{name}.wav" }
  end

  def self.known?(name)
    CUES.include?(name.to_s)
  end

  def self.path_for(name)
    catalog[name.to_s]
  end
end
