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
    :target_taps, :forbidden, :target, :guess_keys, :items, :order, :goal,
    :swing, :layers, :theme_id, keyword_init: true
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
      tokens = guess_tokens(body)
      seen = {}
      all_guess_keys.each do |key|
        folded = fold_name(key)
        next if folded.blank? || seen[folded]
        next unless tokens.include?(folded)

        seen[folded] = key
      end
      seen.values
    end

    def fold_name(text)
      ActiveSupport::Inflector.transliterate(text.to_s.downcase)
    end

    def freeze_window
      raw = remote_variant.is_a?(Hash) ? remote_variant["window_ms"] : nil
      (raw.presence || 2000).to_i
    end

    def matches_guess?(body)
      tokens = guess_tokens(body)
      all_guess_keys.any? { |key| tokens.include?(fold_name(key)) }
    end

    def guess_tokens(body)
      fold_name(body).scan(/[a-z0-9]+/)
    end

    def item_pairs
      Array(items).map do |item|
        if item.is_a?(Hash)
          { "key" => (item["key"] || item[:key]).to_s, "label" => item_copy(item) }
        else
          { "key" => item.to_s, "label" => item_copy(item) }
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

    def copy(field, **opts)
      fallback = opts.key?(:default) ? opts[:default] : public_send(field)
      I18n.t("games.#{theme_id}.rounds.#{id}.#{field}", default: fallback)
    end

    def choice_copy(choice)
      key = if choice.is_a?(Hash)
        (choice["key"] || choice[:key] || choice["label"] || choice[:label]).to_s
      else
        choice.to_s
      end
      fallback = if choice.is_a?(Hash)
        (choice["label"] || choice[:label] || key).to_s
      else
        choice.to_s
      end
      I18n.t("games.#{theme_id}.rounds.#{id}.choices.#{key}", default: fallback)
    end

    def item_copy(item)
      key = item.is_a?(Hash) ? (item["key"] || item[:key]).to_s : item.to_s
      fallback = item.is_a?(Hash) ? (item["label"] || item[:label] || key).to_s : item.to_s
      I18n.t("games.#{theme_id}.rounds.#{id}.items.#{key}", default: fallback)
    end

    def layer_copy(layer, field)
      key = layer["key"].to_s
      I18n.t("games.#{theme_id}.rounds.#{id}.layers.#{key}.#{field}", default: layer[field].to_s)
    end

    def beat_copy(beat, field)
      key = beat["key"].to_s
      fallback = (beat[field] || beat["shout"] || key).to_s
      I18n.t("games.#{theme_id}.rounds.#{id}.beats.#{key}.#{field}", default: fallback)
    end

    def remote_instructions
      raw = remote_variant.is_a?(Hash) ? remote_variant["instructions"] : nil
      I18n.t("games.#{theme_id}.rounds.#{id}.remote_instructions", default: raw)
    end

    def forbidden_copy
      Array(forbidden).map do |word|
        slug = ActiveSupport::Inflector.transliterate(word.to_s).downcase.gsub(/[^a-z0-9]/, "")
        I18n.t("games.#{theme_id}.rounds.#{id}.forbidden.#{slug}", default: word.to_s)
      end
    end

    def all_guess_keys
      keys = Array(guess_keys).map(&:to_s)
      Locale::AVAILABLE.each do |code|
        extra = I18n.t("games.#{theme_id}.rounds.#{id}.guess_keys", locale: Locale.i18n(code), default: [])
        keys.concat(Array(extra).map(&:to_s)) if extra.is_a?(Array)
      end
      keys.map { |key| key.to_s.strip }.reject(&:blank?).uniq
    end

    def story_beats
      Array(remote_variant&.fetch("beats", nil)).map do |beat|
        {
          "key" => beat["key"].to_s,
          "shout" => beat_copy(beat, "shout"),
          "picto" => beat["picto"].to_s.presence || "sparkle",
          "label" => beat_copy(beat, "label")
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

    def swing?
      swing == true || swing.to_s == "true"
    end

    def layered_finale?
      finale? && Array(layers).size >= 2
    end

    def swing_points(night, team)
      base = points
      return base unless swing?
      return base unless team

      others = night.teams.reload.reject { |row| row.id == team.id }
      best = others.map(&:cached_score).max
      return base if best.nil?

      me = team.cached_score.to_i
      me < best ? (best - me) + 1 : base
    end
  end

  Theme = Struct.new(:id, :title, :tagline, keyword_init: true) do
    def copy(field)
      I18n.t("games.#{id}.#{field}", default: public_send(field))
    end
  end

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
    @rounds = data.fetch("rounds").map { |row| build_round(row, @theme.id) }
  end

  def find_round(id)
    rounds.find { |round| round.id == id } || raise(Error, "Unknown round #{id}")
  end

  private

  def build_round(row, theme_id)
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
      goal: row["goal"],
      swing: row["swing"],
      layers: normalize_layers(row["layers"]),
      theme_id: theme_id
    )
  end

  def normalize_layers(raw)
    Array(raw).map do |layer|
      next {} unless layer.is_a?(Hash)

      {
        "key" => layer["key"].to_s,
        "label" => layer["label"].to_s,
        "text" => layer["text"].to_s,
        "host" => layer["host"].to_s,
        "picto" => layer["picto"].to_s.presence || "sparkle",
        "image" => layer["image"].to_s,
        "clip" => layer["clip"].to_s
      }
    end
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
      if row["layers"].present? || row["swing"]
        layers = Array(row["layers"])
        raise Error, "round #{row['id']} needs at least two layers" if layers.size < 2
        layers.each do |layer|
          %w[key label text host picto image].each do |field|
            raise Error, "round #{row['id']} layer missing #{field}" if layer.is_a?(Hash) && layer[field].to_s.strip.blank?
          end
        end
      end
      if row["remote"] == false && row["remote_variant"].blank?
        # allowed, but graded D — engine still loads it
      end
    end
  end
end
