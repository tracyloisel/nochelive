class QuizDefinition
  class Error < StandardError; end

  CANONS = %w[bible bom dc pgp].freeze
  PACK_COUNT = 35
  QUESTIONS_PER_PACK = 10
  CURVE_POINTS = [ 5, 5, 5, 8, 8, 8, 12, 12, 15, 25 ].freeze
  CURVE_DURATION = [ 0, 0, 0, 20, 20, 20, 15, 15, 15, 15 ].freeze
  CURVE_INTENSITY = [ 1, 1, 2, 2, 2, 3, 3, 4, 4, 5 ].freeze
  CATALOG_ID = "libre"
  # Every authored pack belongs to the permanent adventure catalog. An
  # expedition never owns a second kind of quiz: it only selects pack ids from
  # this list and gives them a temporary editorial presentation.
  CATALOG_FILES = %w[libre doctrine_and_covenants_89 parabolas improbables psalms_102_150_fast].freeze
  ARCHIVED_CATALOG_FILES = %w[expedition_psalms_2026].freeze
  CATALOG_INSERTIONS = { "dc89_word_of_wisdom" => "inicios" }.freeze
  STUDY_PREFIXES = {
    "bible" => %w[ot/ nt/],
    "bom" => %w[bofm/],
    "dc" => %w[dc-testament/],
    "pgp" => %w[pgp/abr pgp/moses pgp/js-h]
  }.freeze

  Scripture = Struct.new(:canon, :cite, :study, keyword_init: true)

  Question = Struct.new(
    :id, :pack_id, :position, :question, :choices, :correct_choice, :answer,
    :reader_cta_label, :points, :duration, :intensity, :scripture, :presentation,
    :localized_copy,
    keyword_init: true
  ) do
    def copy(field)
      authored = authored_copy(field)
      return authored if authored.present?

      I18n.t("quizzes.#{pack_id}.questions.#{id}.#{field}", default: public_send(field))
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
      authored = Array(locale_copy&.fetch("choices", nil)).find do |item|
        item.is_a?(Hash) && item["key"].to_s == key
      end
      return authored["label"].to_s if authored&.fetch("label", nil).to_s.present?

      I18n.t("quizzes.#{pack_id}.questions.#{id}.choices.#{key}", default: fallback)
    end

    def slam?
      position == QUESTIONS_PER_PACK
    end

    def timed?
      duration.to_i > 0
    end

    def shuffled_choices(seed)
      choices.shuffle(random: Random.new(seed.to_i))
    end

    def scripture_cite
      locale_copy&.fetch("scripture_cite", nil).to_s.presence || scripture&.cite
    end

    private

      def authored_copy(field)
        key = { question: "prompt", answer: "feedback" }.fetch(field.to_sym, field.to_s)
        locale_copy&.fetch(key, nil).to_s.presence
      end

      def locale_copy
        return unless localized_copy.is_a?(Hash)

        localized_copy[I18n.locale.to_s]
      end
  end

  Pack = Struct.new(:id, :title, :kicker, :lede, :questions, :readings, :localized_copy, keyword_init: true) do
    def copy(field)
      authored = localized_copy&.dig(I18n.locale.to_s, field.to_s).to_s.presence
      return authored if authored

      I18n.t("quizzes.#{id}.#{field}", default: public_send(field))
    end

    def question_at(position)
      questions.find { |question| question.position == position } ||
        raise(Error, "Unknown question #{position} in pack #{id}")
    end
  end

  attr_reader :packs, :archived_packs

  def self.catalog
    @catalog ||= load
  end

  def self.load(id = CATALOG_ID)
    if id == CATALOG_ID
      packs = CATALOG_FILES.flat_map do |catalog_id|
        path = Rails.root.join("config/quizzes/#{catalog_id}.yml")
        raise Error, "Unknown quiz catalog #{catalog_id}" unless path.exist?

        Array(YAML.safe_load_file(path)["packs"])
      end
      archived_packs = ARCHIVED_CATALOG_FILES.flat_map do |catalog_id|
        path = Rails.root.join("config/quizzes/#{catalog_id}.yml")
        raise Error, "Unknown archived quiz catalog #{catalog_id}" unless path.exist?

        Array(YAML.safe_load_file(path)["packs"])
      end
      return new({ "packs" => insert_catalog_packs(packs) }, archived_data: { "packs" => archived_packs })
    end

    path = Rails.root.join("config/quizzes/#{id}.yml")
    raise Error, "Unknown quiz catalog #{id}" unless path.exist?

    new(YAML.safe_load_file(path))
  end

  def self.reset!
    @catalog = nil
  end

  def self.insert_catalog_packs(packs)
    ordered = packs.dup
    CATALOG_INSERTIONS.each do |pack_id, predecessor_id|
      pack = ordered.find { |row| row["id"].to_s == pack_id }
      predecessor_index = ordered.index { |row| row["id"].to_s == predecessor_id }
      raise Error, "Unknown inserted pack #{pack_id}" unless pack
      raise Error, "Unknown predecessor #{predecessor_id} for #{pack_id}" unless predecessor_index

      ordered.delete(pack)
      predecessor_index = ordered.index { |row| row["id"].to_s == predecessor_id }
      ordered.insert(predecessor_index + 1, pack)
    end
    ordered
  end
  private_class_method :insert_catalog_packs

  def initialize(data, archived_data: nil)
    validate!(data)
    @packs = Array(data["packs"]).map { |row| build_pack(row) }
    archived_rows = Array(archived_data&.fetch("packs", []))
    archived_rows.each { |row| validate_pack!(row) }
    all_ids = @packs.map(&:id) + archived_rows.map { |row| row["id"].to_s }
    raise Error, "duplicate active and archived pack ids" unless all_ids.uniq.size == all_ids.size

    @archived_packs = archived_rows.map { |row| build_pack(row) }
  end

  def pack_ids
    packs.map(&:id)
  end

  def find_pack(id)
    all_packs.find { |pack| pack.id == id } || raise(Error, "Unknown pack #{id}")
  end

  def find_question(pack_id, question_id)
    find_pack(pack_id).questions.find { |question| question.id == question_id.to_s } ||
      raise(Error, "Unknown question #{question_id} in pack #{pack_id}")
  end

  def all_questions
    packs.flat_map(&:questions)
  end

  def archived_pack_ids
    archived_packs.map(&:id)
  end

  def all_packs
    packs + archived_packs
  end

  private

  def build_pack(row)
    pack_id = row.fetch("id")
    localized_copy = stringify_localized_copy(row["copy"])
    base_copy = base_localized_copy(localized_copy)
    questions = Array(row["questions"]).each_with_index.map do |question, index|
      build_question(question, pack_id, index + 1)
    end
    Pack.new(
      id: pack_id,
      title: row["title"].presence || base_copy.fetch("title"),
      kicker: row["kicker"].presence || base_copy.fetch("kicker"),
      lede: row["lede"].presence || base_copy.fetch("lede"),
      questions: questions,
      readings: Array(row["readings"]).map do |reading|
        { "study" => reading.fetch("study").to_s, "cite" => reading.fetch("cite").to_s }
      end,
      localized_copy:
    )
  end

  def build_question(row, pack_id, position)
    scripture_data = row.fetch("scripture")
    localized_copy = stringify_localized_copy(row["copy"])
    base_copy = base_localized_copy(localized_copy)
    Question.new(
      id: row.fetch("id"),
      pack_id: pack_id,
      position: position,
      question: (row["question"].presence || base_copy.fetch("prompt")).to_s,
      choices: Array(row["choices"].presence || base_copy.fetch("choices")).map { |choice| stringify_choice(choice) },
      correct_choice: row.fetch("correct_choice").to_s,
      answer: (row["answer"].presence || base_copy.fetch("feedback")).to_s,
      reader_cta_label: (row["reader_cta_label"].presence || base_copy["reader_cta_label"]).to_s,
      points: row.fetch("points").to_i,
      duration: row.fetch("duration").to_i,
      intensity: row.fetch("intensity").to_i,
      scripture: Scripture.new(
        canon: scripture_data.fetch("canon").to_s,
        cite: scripture_data.fetch("cite").to_s,
        study: scripture_data.fetch("study").to_s
      ),
      presentation: stringify_presentation(row["presentation"]),
      localized_copy:
    )
  end

  def stringify_choice(choice)
    {
      "key" => (choice["key"] || choice[:key]).to_s,
      "label" => (choice["label"] || choice[:label]).to_s
    }
  end

  def stringify_presentation(raw)
    hash = raw.is_a?(Hash) ? raw : {}
    { "image" => (hash["image"] || hash[:image] || hash["current_image"] || hash[:current_image]).to_s }
  end

  def stringify_localized_copy(raw)
    raw.is_a?(Hash) ? raw.deep_stringify_keys : {}
  end

  def base_localized_copy(copy)
    copy["es"] || copy.values.first || {}
  end

  def validate!(data)
    packs = data["packs"]
    raise Error, "packs missing" unless packs.is_a?(Array)
    raise Error, "expected #{PACK_COUNT} packs" unless packs.size == PACK_COUNT

    pack_ids = packs.map { |row| row["id"].to_s }
    raise Error, "pack missing id" if pack_ids.any?(&:blank?)
    raise Error, "duplicate pack ids" unless pack_ids.uniq.size == pack_ids.size

    packs.each do |pack|
      validate_pack!(pack)
    end
  end

  def validate_pack!(pack)
    pack_id = pack["id"].to_s
    localized_copy = stringify_localized_copy(pack["copy"])
    base_copy = base_localized_copy(localized_copy)
    raise Error, "pack #{pack_id} missing title" if (pack["title"].presence || base_copy["title"]).to_s.strip.blank?
    raise Error, "pack #{pack_id} missing kicker" if (pack["kicker"].presence || base_copy["kicker"]).to_s.strip.blank?
    raise Error, "pack #{pack_id} missing lede" if (pack["lede"].presence || base_copy["lede"]).to_s.strip.blank?
    validate_localized_pack_copy!(pack_id, localized_copy) if localized_copy.present?

    questions = pack["questions"]
    raise Error, "pack #{pack_id} needs #{QUESTIONS_PER_PACK} questions" unless questions.is_a?(Array) && questions.size == QUESTIONS_PER_PACK

    ids = questions.map { |row| row["id"].to_s }
    raise Error, "pack #{pack_id} has a question without id" if ids.any?(&:blank?)
    raise Error, "duplicate question ids" unless ids.uniq.size == ids.size

    points = questions.map { |row| row["points"].to_i }
    raise Error, "pack #{pack_id} points off curve" unless points == CURVE_POINTS

    durations = questions.map { |row| row["duration"].to_i }
    raise Error, "pack #{pack_id} duration off curve" unless durations == CURVE_DURATION

    intensities = questions.map { |row| row["intensity"].to_i }
    raise Error, "pack #{pack_id} intensity drops" if intensities.each_cons(2).any? { |left, right| right < left }
    raise Error, "pack #{pack_id} intensity off curve" unless intensities == CURVE_INTENSITY

    first_points, slam_points = points.first, points.last
    raise Error, "pack #{pack_id} slam too small" if slam_points < first_points * 3

    questions.each_with_index do |row, index|
      validate_question!(row, pack_id, index + 1)
    end
  end

  def validate_question!(row, pack_id, position)
    qid = row["id"].to_s.presence || "#{pack_id}##{position}"
    localized_copy = stringify_localized_copy(row["copy"])
    base_copy = base_localized_copy(localized_copy)
    raise Error, "#{qid} missing question" if (row["question"].presence || base_copy["prompt"]).to_s.strip.blank?
    raise Error, "#{qid} missing answer" if (row["answer"].presence || base_copy["feedback"]).to_s.strip.blank?

    choices = Array(row["choices"].presence || base_copy["choices"])
    raise Error, "#{qid} needs 2–4 choices" unless choices.size.between?(2, 4)

    keys = choices.map do |choice|
      unless choice.is_a?(Hash) && choice["key"].to_s.present? && choice["label"].to_s.present?
        raise Error, "#{qid} choice needs key and label"
      end
      choice["key"].to_s
    end
    correct = row["correct_choice"].to_s
    raise Error, "#{qid} correct_choice mismatch" if correct.blank? || !keys.include?(correct)
    validate_localized_question_copy!(qid, localized_copy, keys) if localized_copy.present?

    scripture = row["scripture"]
    raise Error, "#{qid} missing scripture" unless scripture.is_a?(Hash)

    canon = scripture["canon"].to_s
    raise Error, "#{qid} bad canon #{canon}" unless CANONS.include?(canon)
    raise Error, "#{qid} missing cite" if scripture["cite"].to_s.strip.blank?

    study = scripture["study"].to_s.strip
    raise Error, "#{qid} missing study" if study.blank?
    prefixes = STUDY_PREFIXES.fetch(canon)
    raise Error, "#{qid} bad study path #{study}" unless prefixes.any? { |prefix| study.start_with?(prefix) }

    image = (row.dig("presentation", "image") || row.dig("presentation", "current_image")).to_s
    raise Error, "#{qid} missing image" if image.blank?
    expected_stem = "quizzes/#{pack_id}/#{row['id']}"
    stem = image.sub(/\.(?:jpe?g|png|webp)\z/i, "")
    raise Error, "#{qid} image must be #{expected_stem}.(jpg|png|webp)" unless stem == expected_stem
  end

  def validate_localized_pack_copy!(pack_id, copy)
    validate_locales!("pack #{pack_id}", copy)
    copy.each do |locale, row|
      %w[title kicker lede].each do |field|
        raise Error, "pack #{pack_id} #{locale} missing #{field}" if row[field].to_s.strip.blank?
      end
    end
  end

  def validate_localized_question_copy!(question_id, copy, expected_choice_keys)
    validate_locales!(question_id, copy)
    copy.each do |locale, row|
      %w[prompt feedback].each do |field|
        raise Error, "#{question_id} #{locale} missing #{field}" if row[field].to_s.strip.blank?
      end
      choices = Array(row["choices"])
      keys = choices.map { |choice| choice.is_a?(Hash) ? choice["key"].to_s : "" }
      raise Error, "#{question_id} #{locale} choice keys mismatch" unless keys == expected_choice_keys
      raise Error, "#{question_id} #{locale} choice missing label" if choices.any? { |choice| choice["label"].to_s.strip.blank? }
    end
  end

  def validate_locales!(scope, copy)
    locales = copy.keys.map(&:to_s)
    return if locales.sort == Locale::AVAILABLE.sort

    raise Error, "#{scope} copy must contain exactly #{Locale::AVAILABLE.join(', ')}"
  end
end
