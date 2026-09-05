require "test_helper"
require "digest"

class QuizDefinitionTest < ActiveSupport::TestCase
  LOCKED_PACK_IDS = %w[
    coronas placas hermanas abish profetas jehova nazareno moises abraham
    kolob premortal exaltacion jose inicios dc89_word_of_wisdom pruebas_profetas pruebas_heroes milagros
    apocalipsis segunda_venida milenio
    perdido_encontrado secretos_reino amar_projimo velar_servir sobre_roca
    simbolos_mormon parabolas_profetas improbables
    psalms_living_god psalms_servant_king psalms_hears_knows
    psalms_walk_with_god psalms_build_home psalms_every_breath
  ].freeze

  setup do
    QuizDefinition.reset!
  end

  test "loads every permanent pack with ten questions on the curve" do
    catalog = QuizDefinition.catalog
    assert_equal QuizDefinition::PACK_COUNT, catalog.packs.size
    assert_equal LOCKED_PACK_IDS, catalog.pack_ids
    assert_equal QuizDefinition::PACK_COUNT * QuizDefinition::QUESTIONS_PER_PACK, catalog.all_questions.size

    catalog.packs.each do |pack|
      assert_equal QuizDefinition::QUESTIONS_PER_PACK, pack.questions.size, pack.id
      assert pack.lede.present?, pack.id
      assert pack.kicker.present?, pack.id
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

  test "timed questions start outside the warn ratio" do
    timed = QuizDefinition.catalog.all_questions.select(&:timed?)
    assert timed.any?
    assert_equal [ 15, 20 ], timed.map(&:duration).uniq.sort
    timed.each do |question|
      refute ApplicationController.helpers.play_timer_warn?(question.duration, question.duration), question.id
      refute ApplicationController.helpers.play_timer_hot?(question.duration, question.duration), question.id
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

  test "every question still path is quizzes pack id with an approved raster extension" do
    questions = QuizDefinition.catalog.all_questions
    questions.each do |question|
      image = question.presentation["image"]
      assert_match(%r{\Aquizzes/#{Regexp.escape(question.pack_id)}/#{Regexp.escape(question.id)}\.(?:jpg|png|webp)\z}, image)
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

  test "last-days trilogy bridges the Bible and Book of Mormon" do
    packs = %w[apocalipsis segunda_venida milenio].map { |id| QuizDefinition.catalog.find_pack(id) }

    packs.each do |pack|
      canons = pack.questions.map { |question| question.scripture.canon }
      assert_includes canons, "bible", pack.id
      assert_includes canons, "bom", pack.id
    end

    assert_match(/REY DE REYES/, packs[0].questions.last.answer)
    assert_match(/nubes/, packs[1].questions.last.answer)
    assert_match(/reveladas/, packs[2].questions.last.answer)
  end

  test "last-days trilogy has authored stills and celestial modes" do
    modes = YAML.safe_load_file(Rails.root.join("config/media/quiz_stills.yml")).fetch("stills")
    expected_modes = {
      "apocalipsis" => "dark",
      "segunda_venida" => "dark",
      "milenio" => "light"
    }

    expected_modes.each do |pack_id, expected_mode|
      QuizDefinition.catalog.find_pack(pack_id).questions.each do |question|
        assert still_file(question).file?, question.presentation["image"]
        assert_equal expected_mode, modes.fetch(question.presentation["image"]).fetch("mode")
      end
    end

    stills = expected_modes.keys.flat_map do |pack_id|
      QuizDefinition.catalog.find_pack(pack_id).questions.map { |question| still_file(question) }
    end
    digests = stills.map { |still| Digest::SHA256.file(still).hexdigest }
    assert_equal stills.size, digests.uniq.size, "last-days question stills must be unique"
  end

  test "copy in English returns English" do
    I18n.with_locale(:en) do
      pack = QuizDefinition.catalog.find_pack("coronas")
      question = pack.question_at(1)
      assert_equal "David, Saul, and Solomon", pack.copy(:title)
      assert_equal "Kings of Israel", pack.copy(:kicker)
      assert_match(/Solomon/i, pack.copy(:lede))
      assert_match(/anointed/i, question.copy(:question))
      assert_match(/Samuel anointed/i, question.copy(:answer))
      samuel = question.choices.find { |choice| choice["key"] == "samuel" }
      assert_equal "Samuel", question.choice_copy(samuel)
    end
  end

  test "copy in French returns French" do
    I18n.with_locale(:fr) do
      pack = QuizDefinition.catalog.find_pack("coronas")
      assert_equal "David, Saül et Salomon", pack.copy(:title)
      assert_equal "Rois d’Israël", pack.copy(:kicker)

      book_of_mormon_pack = QuizDefinition.catalog.find_pack("placas")
      assert_equal "Histoires du Livre de Mormon", book_of_mormon_pack.copy(:title)
      assert_equal "Léhi, Néphi et Moroni", book_of_mormon_pack.copy(:kicker)
    end
  end

  test "copy for the Psalms expedition returns Spanish" do
    I18n.with_locale(:es) do
      pack = QuizDefinition.catalog.find_pack("exp_psalms_disappearing_voice")
      question = pack.question_at(1)

      assert_equal "La voz que desaparece", pack.copy(:title)
      assert_equal "Salmos 102–103", pack.copy(:kicker)
      assert_equal "¿Qué teme la voz al comienzo del Salmo 102?", question.copy(:question)
      assert_equal "Desaparecer", question.choice_copy(question.choices.first)
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
    data["packs"][0].delete("kicker")
    assert_raises(QuizDefinition::Error) { QuizDefinition.new(data) }

    data = catalog_data
    data["packs"][0].delete("lede")
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
    assert_equal QuizDefinition::PACK_COUNT, second.packs.size
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
    packs = QuizDefinition::CATALOG_FILES.flat_map do |catalog_id|
      YAML.safe_load_file(Rails.root.join("config/quizzes/#{catalog_id}.yml")).fetch("packs")
    end
    { "packs" => packs }.deep_dup
  end

  def still_file(question)
    asset = Frontend::MediaManifest.fetch_source("media/#{question.presentation['image']}")
    Rails.root.join("media/masters", asset.fetch("source"))
  end
end
