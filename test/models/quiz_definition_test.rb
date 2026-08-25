require "test_helper"

class QuizDefinitionTest < ActiveSupport::TestCase
  LOCKED_PACK_IDS = %w[
    coronas placas hermanas abish profetas jehova nazareno moises abraham
    kolob premortal exaltacion jose inicios pruebas_profetas pruebas_heroes milagros
  ].freeze

  setup do
    QuizDefinition.reset!
  end

  test "loads seventeen packs of ten questions on the curve" do
    catalog = QuizDefinition.catalog
    assert_equal QuizDefinition::PACK_COUNT, catalog.packs.size
    assert_equal LOCKED_PACK_IDS, catalog.pack_ids
    assert_equal QuizDefinition::PACK_COUNT * QuizDefinition::QUESTIONS_PER_PACK, catalog.all_questions.size

    catalog.packs.each do |pack|
      assert_equal QuizDefinition::QUESTIONS_PER_PACK, pack.questions.size, pack.id
      assert_equal QuizDefinition::CURVE_POINTS, pack.questions.map(&:points), pack.id
      assert_equal QuizDefinition::CURVE_DURATION, pack.questions.map(&:duration), pack.id
      assert_equal QuizDefinition::CURVE_INTENSITY, pack.questions.map(&:intensity), pack.id
      assert pack.question_at(10).points >= pack.question_at(1).points * 3, pack.id
      refute pack.question_at(1).timed?
      refute pack.question_at(1).slam?
      assert pack.question_at(4).timed?
      assert pack.question_at(10).slam?
      assert pack.question_at(10).timed?
    end
  end

  test "every question has a canon cite and study path" do
    QuizDefinition.catalog.all_questions.each do |question|
      assert_includes QuizDefinition::CANONS, question.scripture.canon, question.id
      assert question.scripture.cite.present?, question.id
      assert question.scripture.study.present?, question.id
      prefixes = QuizDefinition::STUDY_PREFIXES.fetch(question.scripture.canon)
      assert prefixes.any? { |prefix| question.scripture.study.start_with?(prefix) }, "#{question.id} #{question.scripture.study}"
    end
  end

  test "question ids are disjoint from the night rounds" do
    night_ids = GameDefinition.default.rounds.map(&:id)
    quiz_ids = QuizDefinition.catalog.all_questions.map(&:id)
    overlap = quiz_ids & night_ids
    assert_empty overlap
  end

  test "every question still path is quizzes/pack/id.jpg" do
    questions = QuizDefinition.catalog.all_questions
    questions.each do |question|
      image = question.presentation["image"]
      assert_equal "quizzes/#{question.pack_id}/#{question.id}.jpg", image
      assert_match(%r{\Aquizzes/#{Regexp.escape(question.pack_id)}/#{Regexp.escape(question.id)}\.jpg\z}, image)
    end

    existing = questions.select { |question| still_file(question).file? }
    assert_equal questions.size, existing.size, "missing quiz stills: #{(questions - existing).map { |q| q.presentation['image'] }.join(', ')}"

    questions.each do |question|
      path = still_file(question)
      assert path.file?, "#{question.id} missing #{path}"
    end
  end

  test "jose is the life of Joseph and inicios is 1830" do
    jose = QuizDefinition.catalog.find_pack("jose")
    first = jose.questions.first
    blob = "#{first.question} #{first.scripture.cite} #{first.answer}"
    assert_match(/JS-H|Sharon/i, blob)

    inicios = QuizDefinition.catalog.find_pack("inicios")
    text = inicios.questions.map { |question| "#{question.question} #{question.scripture.cite} #{question.answer}" }.join(" ")
    assert_match(/1830|DyC 20/, text)
  end

  test "copy in English returns English" do
    I18n.with_locale(:en) do
      pack = QuizDefinition.catalog.find_pack("coronas")
      question = pack.question_at(1)
      assert_equal "Kings", pack.copy(:title)
      assert_match(/anointed/i, question.copy(:question))
      assert_match(/Samuel anointed/i, question.copy(:answer))
      samuel = question.choices.find { |choice| choice["key"] == "samuel" }
      assert_equal "Samuel", question.choice_copy(samuel)
    end
  end

  test "rejects duplicate ids missing scripture intensity drop and wrong points" do
    assert_raises(QuizDefinition::Error) { QuizDefinition.load("nope") }
    assert_raises(QuizDefinition::Error) { QuizDefinition.catalog.find_pack("missing") }

    data = catalog_data
    data["packs"][0]["questions"][1]["id"] = data["packs"][0]["questions"][0]["id"]
    assert_raises(QuizDefinition::Error) { QuizDefinition.new(data) }

    data = catalog_data
    data["packs"][0]["questions"][0].delete("scripture")
    assert_raises(QuizDefinition::Error) { QuizDefinition.new(data) }

    data = catalog_data
    data["packs"][0]["questions"][9]["intensity"] = 1
    assert_raises(QuizDefinition::Error) { QuizDefinition.new(data) }

    data = catalog_data
    data["packs"][0]["questions"][0]["points"] = 99
    assert_raises(QuizDefinition::Error) { QuizDefinition.new(data) }
  end

  test "reset reloads the catalog" do
    first = QuizDefinition.catalog
    QuizDefinition.reset!
    second = QuizDefinition.catalog
    refute_same first, second
    assert_equal 17, second.packs.size
  end

  test "shuffled choices move the correct key away from first place" do
    question = QuizDefinition.catalog.find_pack("hermanas").question_at(9)
    yaml_first = (question.choices.first["key"] || question.choices.first[:key]).to_s
    assert_equal question.correct_choice, yaml_first

    moved = (1..20).any? do |seed|
      shuffled = question.shuffled_choices(seed)
      first = (shuffled.first["key"] || shuffled.first[:key]).to_s
      first != yaml_first
    end
    assert moved
  end

  private

  def catalog_data
    YAML.safe_load_file(Rails.root.join("config/quizzes/libre.yml")).deep_dup
  end

  def still_file(question)
    Rails.public_path.join("media/#{question.presentation['image']}")
  end
end
