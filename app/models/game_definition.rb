class GameDefinition
  class Error < StandardError; end

  KNOWN_TYPES = %w[
    buzzer finale multiple_choice true_false ordering mime taboo drawing
    physical_target freeze_dance elimination scavenger_hunt category_race
    pose audio_reaction team_vote rapid_tap
  ].freeze

  Round = Struct.new(
    :id, :type, :title, :icon, :question, :answer, :reference, :instructions,
    :choices, :correct_choice, :points, :points_max, :duration, :difficulty,
    :intensity, :remote, :remote_variant, :reward, :presentation, :sfx,
    :target_taps, :forbidden, :target, :guess_keys, :items, :order, :goal, keyword_init: true
  ) do
    def buzzer? = type.in?(%w[buzzer finale])
    def finale? = type == "finale"
    def choice? = type.in?(%w[multiple_choice true_false])
    def has_choices? = Array(choices).any? && correct_choice.present?
    def rapid_tap? = type == "rapid_tap"
    def physical? = type == "physical_target"
    def pose? = type == "pose"
    def mime? = type == "mime"
    def taboo? = type == "taboo"
    def scavenger? = type == "scavenger_hunt"
    def ordering? = type == "ordering"
    def freeze? = type == "freeze_dance"
    def category? = type == "category_race"
    def vote? = type == "team_vote"
    def implemented?
      type.in?(%w[buzzer finale multiple_choice true_false rapid_tap physical_target pose mime taboo scavenger_hunt ordering freeze_dance category_race team_vote])
    end

    def category_goal
      (goal.presence || 3).to_i
    end

    def matching_names(body)
      hay = fold_name(body)
      guess_keys.select { |key| hay.include?(fold_name(key)) }.uniq
    end

    def fold_name(text)
      ActiveSupport::Inflector.transliterate(text.to_s.downcase)
    end

    def freeze_window
      raw = remote_variant.is_a?(Hash) ? remote_variant["window_ms"] : nil
      (raw.presence || 2000).to_i
    end

    def matches_guess?(body)
      hay = ActiveSupport::Inflector.transliterate(body.to_s.downcase)
      guess_keys.any? { |key| hay.include?(ActiveSupport::Inflector.transliterate(key.to_s.downcase)) }
    end

    def item_pairs
      Array(items).map do |item|
        if item.is_a?(Hash)
          { "key" => (item["key"] || item[:key]).to_s, "label" => (item["label"] || item[:label]).to_s }
        else
          { "key" => item.to_s, "label" => item.to_s }
        end
      end
    end

    def matches_order?(body)
      body.to_s.split(",").map(&:strip) == Array(order).map(&:to_s)
    end

    def shuffled_items(seed)
      item_pairs.shuffle(random: Random.new(seed.to_i))
    end

    def order_labels(body)
      lookup = item_pairs.index_by { |item| item["key"] }
      body.to_s.split(",").map { |key| lookup.dig(key.strip, "label") || key }
    end

    def variant_choices
      Array(remote_variant&.fetch("choices", nil))
    end

    def variant_correct
      remote_variant&.fetch("correct_choice", nil)
    end

    def story_path?
      remote_type == "story_path"
    end

    def story_beats
      Array(remote_variant&.fetch("beats", nil)).map do |beat|
        {
          "key" => beat["key"].to_s,
          "shout" => beat["shout"].to_s,
          "picto" => beat["picto"].to_s.presence || "sparkle",
          "label" => (beat["label"] || beat["shout"]).to_s
        }
      end
    end

    def story_keys
      story_beats.map { |beat| beat["key"] }
    end

    def matches_path?(body)
      body.to_s.split(",").map(&:strip) == story_keys
    end

    def path_labels(body)
      lookup = story_beats.index_by { |beat| beat["key"] }
      body.to_s.split(",").map { |key| lookup.dig(key.strip, "shout") || key }
    end

    def remote_grade
      return "A" if remote && remote_variant.blank?
      return "B" if remote_variant.present?
      "D"
    end

    def remote_type
      remote_variant&.fetch("type", nil) || (remote ? type : nil)
    end

    def tap_goal
      target_taps || remote_variant&.fetch("taps", nil).to_i.nonzero? || 10
    end
  end

  Theme = Struct.new(:id, :title, :tagline, keyword_init: true)

  attr_reader :theme, :rounds

  def self.load(id)
    path = Rails.root.join("config/games/#{id}.yml")
    raise Error, "Unknown game #{id}" unless path.exist?

    data = YAML.safe_load_file(path)
    new(data)
  end

  def self.default
    load("reyes_y_profetas")
  end

  def initialize(data)
    validate!(data)
    theme_data = data.fetch("theme")
    @theme = Theme.new(
      id: theme_data.fetch("id"),
      title: theme_data.fetch("title"),
      tagline: theme_data["tagline"]
    )
    @rounds = data.fetch("rounds").map { |row| build_round(row) }
  end

  def find_round(id)
    rounds.find { |round| round.id == id } || raise(Error, "Unknown round #{id}")
  end

  private

  def build_round(row)
    variant = row["remote_variant"]
    Round.new(
      id: row.fetch("id"),
      type: row.fetch("type"),
      title: row.fetch("title"),
      icon: row["icon"],
      question: row["question"].to_s.strip.presence,
      answer: row["answer"].to_s.strip.presence,
      reference: row["reference"],
      instructions: row["instructions"].to_s.strip.presence,
      choices: Array(row["choices"]),
      correct_choice: row["correct_choice"],
      points: row["points"] || row["points_max"] || 10,
      points_max: row["points_max"] || row["points"] || 10,
      duration: row["duration"] || 30,
      difficulty: row["difficulty"] || 1,
      intensity: row["intensity"] || 2,
      remote: row["remote"] != false,
      remote_variant: variant.is_a?(Hash) ? variant : nil,
      reward: row["reward"] || {},
      presentation: row["presentation"] || {},
      sfx: row["sfx"] || {},
      target_taps: row["target_taps"],
      forbidden: Array(row["forbidden"]).map(&:to_s),
      target: row["target"].to_s.strip.presence,
      guess_keys: Array(row["guess_keys"]).map(&:to_s),
      items: Array(row["items"]),
      order: Array(row["order"]).map(&:to_s),
      goal: row["goal"]
    )
  end

  def validate!(data)
    raise Error, "theme.id missing" unless data.dig("theme", "id")
    raise Error, "theme.title missing" unless data.dig("theme", "title")
    rounds = data["rounds"]
    raise Error, "rounds missing" unless rounds.is_a?(Array) && rounds.any?

    ids = rounds.map { |row| row["id"] }
    raise Error, "duplicate round ids" unless ids.uniq.size == ids.size

    rounds.each do |row|
      raise Error, "round missing id" unless row["id"]
      raise Error, "round #{row['id']} missing title" unless row["title"]
      type = row["type"]
      raise Error, "round #{row['id']} unknown type #{type}" unless KNOWN_TYPES.include?(type)
      raise Error, "round #{row['id']} missing points" unless row["points"] || row["points_max"]
      if type.in?(%w[multiple_choice true_false])
        raise Error, "round #{row['id']} needs choices" if Array(row["choices"]).empty?
      end
      if type.in?(%w[buzzer finale]) && row["question"].to_s.strip.present?
        raise Error, "round #{row['id']} needs choices" if Array(row["choices"]).empty?
        raise Error, "round #{row['id']} needs correct_choice" if row["correct_choice"].to_s.blank?
      end
      if type == "taboo"
        raise Error, "round #{row['id']} needs forbidden words" if Array(row["forbidden"]).empty?
        raise Error, "round #{row['id']} needs guess_keys" if Array(row["guess_keys"]).empty?
      end
      if type == "ordering"
        raise Error, "round #{row['id']} needs items" if Array(row["items"]).empty?
        raise Error, "round #{row['id']} needs order" if Array(row["order"]).empty?
      end
      if type == "freeze_dance"
        raise Error, "round #{row['id']} needs instructions" if row["instructions"].to_s.strip.blank?
      end
      if type == "category_race"
        raise Error, "round #{row['id']} needs guess_keys" if Array(row["guess_keys"]).empty?
      end
      if type == "team_vote"
        raise Error, "round #{row['id']} needs a question" if row["question"].to_s.strip.blank?
      end
      if type == "mime" && row.dig("remote_variant", "type") == "story_path"
        raise Error, "round #{row['id']} needs story beats" if Array(row.dig("remote_variant", "beats")).empty?
      end
      if row["remote"] == false && row["remote_variant"].blank?
        # allowed, but graded D — engine still loads it
      end
    end
  end
end
