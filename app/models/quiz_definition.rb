class QuizDefinition
  class Error < StandardError; end

  CANONS = %w[bible bom dc pgp].freeze
  PACK_COUNT = 17
  QUESTIONS_PER_PACK = 10
  CURVE_POINTS = [ 5, 5, 5, 8, 8, 8, 12, 12, 15, 25 ].freeze
  CURVE_DURATION = [ 0, 0, 0, 20, 20, 20, 15, 15, 15, 15 ].freeze
  CURVE_INTENSITY = [ 1, 1, 2, 2, 2, 3, 3, 4, 4, 5 ].freeze
  CATALOG_ID = "libre"
  STUDY_PREFIXES = {
    "bible" => %w[ot/ nt/],
    "bom" => %w[bofm/],
    "dc" => %w[dc-testament/],
    "pgp" => %w[pgp/abr pgp/moses pgp/js-h]
  }.freeze

  Scripture = Struct.new(:canon, :cite, :study, keyword_init: true)

  Question = Struct.new(
    :id, :pack_id, :position, :question, :choices, :correct_choice, :answer,
    :points, :duration, :intensity, :scripture, :presentation,
    keyword_init: true
  ) do
    def copy(field)
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
  end

  Pack = Struct.new(:id, :title, :questions, keyword_init: true) do
    def copy(field)
      I18n.t("quizzes.#{id}.#{field}", default: public_send(field))
    end

    def question_at(position)
      questions.find { |question| question.position == position } ||
        raise(Error, "Unknown question #{position} in pack #{id}")
    end
  end

  attr_reader :packs

  def self.catalog
    @catalog ||= load
  end

  def self.load(id = CATALOG_ID)
    path = Rails.root.join("config/quizzes/#{id}.yml")
    raise Error, "Unknown quiz catalog #{id}" unless path.exist?

    new(YAML.safe_load_file(path))
  end

  def self.reset!
    @catalog = nil
  end

  def initialize(data)
    validate!(data)
    @packs = Array(data["packs"]).map { |row| build_pack(row) }
  end

  def pack_ids
    packs.map(&:id)
  end

  def find_pack(id)
    packs.find { |pack| pack.id == id } || raise(Error, "Unknown pack #{id}")
  end

  def find_question(pack_id, question_id)
    find_pack(pack_id).questions.find { |question| question.id == question_id.to_s } ||
      raise(Error, "Unknown question #{question_id} in pack #{pack_id}")
  end

  def all_questions
    packs.flat_map(&:questions)
  end

  private

  def build_pack(row)
    pack_id = row.fetch("id")
    questions = Array(row["questions"]).each_with_index.map do |question, index|
      build_question(question, pack_id, index + 1)
    end
    Pack.new(id: pack_id, title: row.fetch("title"), questions: questions)
  end

  def build_question(row, pack_id, position)
    scripture_data = row.fetch("scripture")
    Question.new(
      id: row.fetch("id"),
      pack_id: pack_id,
      position: position,
      question: row.fetch("question").to_s,
      choices: Array(row["choices"]).map { |choice| stringify_choice(choice) },
      correct_choice: row.fetch("correct_choice").to_s,
      answer: row.fetch("answer").to_s,
      points: row.fetch("points").to_i,
      duration: row.fetch("duration").to_i,
      intensity: row.fetch("intensity").to_i,
      scripture: Scripture.new(
        canon: scripture_data.fetch("canon").to_s,
        cite: scripture_data.fetch("cite").to_s,
        study: scripture_data.fetch("study").to_s
      ),
      presentation: stringify_presentation(row["presentation"])
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
    { "image" => (hash["image"] || hash[:image]).to_s }
  end

  def validate!(data)
    packs = data["packs"]
    raise Error, "packs missing" unless packs.is_a?(Array)
    raise Error, "expected #{PACK_COUNT} packs" unless packs.size == PACK_COUNT

    pack_ids = packs.map { |row| row["id"].to_s }
    raise Error, "pack missing id" if pack_ids.any?(&:blank?)
    raise Error, "duplicate pack ids" unless pack_ids.uniq.size == pack_ids.size

    question_ids = []
    packs.each do |pack|
      validate_pack!(pack, question_ids)
    end

    night_ids = GameDefinition.default.rounds.map(&:id)
    overlap = question_ids & night_ids
    raise Error, "question ids overlap night rounds: #{overlap.join(', ')}" if overlap.any?
  end

  def validate_pack!(pack, question_ids)
    pack_id = pack["id"].to_s
    raise Error, "pack #{pack_id} missing title" if pack["title"].to_s.strip.blank?

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
      question_ids << row["id"].to_s
    end
  end

  def validate_question!(row, pack_id, position)
    qid = row["id"].to_s.presence || "#{pack_id}##{position}"
    raise Error, "#{qid} missing question" if row["question"].to_s.strip.blank?
    raise Error, "#{qid} missing answer" if row["answer"].to_s.strip.blank?

    choices = Array(row["choices"])
    raise Error, "#{qid} needs 3–4 choices" unless choices.size.between?(3, 4)

    keys = choices.map do |choice|
      unless choice.is_a?(Hash) && choice["key"].to_s.present? && choice["label"].to_s.present?
        raise Error, "#{qid} choice needs key and label"
      end
      choice["key"].to_s
    end
    correct = row["correct_choice"].to_s
    raise Error, "#{qid} correct_choice mismatch" if correct.blank? || !keys.include?(correct)

    scripture = row["scripture"]
    raise Error, "#{qid} missing scripture" unless scripture.is_a?(Hash)

    canon = scripture["canon"].to_s
    raise Error, "#{qid} bad canon #{canon}" unless CANONS.include?(canon)
    raise Error, "#{qid} missing cite" if scripture["cite"].to_s.strip.blank?

    study = scripture["study"].to_s.strip
    raise Error, "#{qid} missing study" if study.blank?
    prefixes = STUDY_PREFIXES.fetch(canon)
    raise Error, "#{qid} bad study path #{study}" unless prefixes.any? { |prefix| study.start_with?(prefix) }

    image = row.dig("presentation", "image").to_s
    expected = "quizzes/#{pack_id}/#{row['id']}.jpg"
    raise Error, "#{qid} image must be #{expected}" unless image == expected
  end
end
