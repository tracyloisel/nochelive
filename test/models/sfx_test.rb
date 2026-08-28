require "test_helper"

class SfxTest < ActiveSupport::TestCase
  test "every named cue has an original recording and no scattered paths in models" do
    Sfx::CUES.each do |name|
      file = Sfx.file_for(name)
      assert file&.exist?, "missing #{name}.mp3"
      assert Sfx.known?(name)
      assert_equal "/sfx/#{name}.mp3", Sfx.path_for(name)
    end
    assert_equal Sfx::CUES.size, Sfx.catalog.size
    assert_match %r{\A/sfx/correct_gold\.mp3\?v=[0-9a-f]{12}\z}, Sfx.catalog.fetch("correct_gold")
    assert_equal Sfx.catalog.fetch("correct_gold"), Sfx.versioned_path_for("correct_gold")
    assert_not Sfx.known?("nope")
    assert_nil Sfx.path_for("nope")
  end

  test "pulse kinds map to named cues" do
    assert_equal "round_open", Sfx.for_pulse("open")
    assert_equal "question_change", Sfx.for_pulse("advance")
    assert_equal "round_lock", Sfx.for_pulse("lock")
    assert_equal "reveal", Sfx.for_pulse("reveal")
    assert_equal "buzzer_hit", Sfx.for_pulse("buzz")
    assert_equal "dramatic_fire", Sfx.for_pulse("freeze")
    assert_equal "chest", Sfx.for_pulse("cheer")
    assert_equal "wrong_soft", Sfx.for_pulse("miss")
    assert Sfx.pulse_without_player?("open")
    assert Sfx.pulse_without_player?("advance")
    assert Sfx.pulse_without_player?("miss")
    assert_not Sfx.pulse_without_player?("buzz")
  end

  test "round yaml overrides pulse and grade cues" do
    salomon = GameDefinition.load("reyes_y_profetas").rounds.find { |row| row.id == "salomon_wisdom" }
    goliath = GameDefinition.load("reyes_y_profetas").rounds.find { |row| row.id == "david_goliath" }
    freeze = GameDefinition.load("reyes_y_profetas").rounds.find { |row| row.id == "freeze_saul" }
    burger = GameDefinition.load("reyes_y_profetas").rounds.find { |row| row.id == "finale_prophet" }

    assert_equal "round_start", Sfx.for_pulse("open", salomon)
    assert_equal "round_open", Sfx.for_pulse("open")
    assert_equal "correct_gold", Sfx.for_pulse("score", salomon)
    assert_equal "correct_gold", Sfx.for_grade(salomon, correct: true)
    assert_equal "wrong_soft", Sfx.for_grade(salomon, correct: false)
    assert_equal "dramatic_fire", Sfx.for_pulse("open", goliath)
    assert_equal "fire_whoosh", Sfx.for_pulse("score", goliath)
    assert_equal "fire_whoosh", Sfx.for_grade(goliath, correct: true)
    assert_equal "dramatic_fire", Sfx.for_pulse("lock", freeze)
    assert_equal "dramatic_fire", Sfx.for_pulse("freeze", freeze)
    assert_equal "royal_fanfare", Sfx.for_pulse("score", burger)
    assert_equal "buzzer_hit", Sfx.for_pulse("buzz", salomon)
  end

  test "mix layers keep the bed and ticks off the event voice" do
    bed_and_ticks = %w[timer_tension study_refuge tick tick_low]
    events = Sfx::CUES - bed_and_ticks
    assert_equal bed_and_ticks.sort, (Sfx::CUES & bed_and_ticks).sort
    assert_includes events, "buzzer_hit"
    assert_includes events, "round_open"
    assert_includes events, "reveal"
    assert_not_includes events, "timer_tension"
    assert_not_includes events, "study_refuge"
  end

  test "mixer lets hits overlay stingers and fades the bed instead of cutting" do
    js = Rails.root.join("app/javascript/controllers/stage_controller.js").read
    hits = %w[buzzer_hit correct_gold wrong_soft score_transfer crown_chime fire_whoosh flame_gold chest study_light study_miss study_turn]
    hits.each { |cue| assert_match(/HIT_CUES[\s\S]{0,500}#{cue}/, js) }
    assert_includes js, "correct_gold: 0.32"
    assert_includes js, "function playHit("
    assert_includes js, "function playStinger("
    assert_includes js, "decodeAudioData"
    assert_includes js, "store.bufferPaths[name] !== path"
    assert_includes js, "store.poolPaths[name] !== path"
    assert_includes js, "function spawnVoice("
    assert_includes js, "BED_OUT_MS"
    assert_includes js, "BED_IN_MS"
    assert_match(/BED_CUES[\s\S]{0,100}study_refuge/, js)
    assert_match(/study_refuge: 0\.14/, js)
    assert_match(/function stageNode\([\s\S]{0,220}SCRIPTURE_BED_SELECTOR[\s\S]{0,220}if \(scripture\) return scripture/, js)
    assert_match(/toggleMute\([\s\S]*?onGesture\(\)\s+playFrom\(document\)/, js)
    cut = js[/const CUT_MS = (\d+)/, 1].to_i
    assert_operator cut, :>=, 180, "stinger crossfade must be long enough to hear the previous cue leave"
    retrigger = js[/const RETRIGGER_MS = (\d+)/, 1].to_i
    assert_operator retrigger, :>=, 200, "same cue must not restart over itself on pulse+click"
    refute_match(/function playTick\([^)]*\) \{\s*if \(stingerPlaying\(\)\) return/, js)
    refute_match(/function timerTick\([^)]*\) \{[\s\S]{0,400}playCue\(low \? "tick_low"/, js)
    assert_includes js, "function syncHalo("
    assert_includes js, "is-timer-hot"
    assert_includes js, "is-timer-pulse"
    assert_includes js, "const TIMER_WARN_RATIO = 0.4"
    assert_includes js, "const TIMER_HOT_RATIO = 0.2"
    refute_includes js, "remain > 20"
    countdown = Rails.root.join("app/javascript/controllers/countdown_controller.js").read
    assert_includes countdown, "const TIMER_WARN_RATIO = 0.4"
    assert_includes countdown, "const TIMER_HOT_RATIO = 0.2"
    assert_includes countdown, "this.askValue"
    assert_includes countdown, "remain > 10 && remain <= 20"
    assert_includes countdown, "remain > 0 && remain <= 10"
    hub = Rails.root.join("app/javascript/controllers/street_hub_controller.js").read
    refute_includes hub, 'play?.("level_up")'
    motion = Rails.root.join("app/javascript/controllers/street_motion_controller.js").read
    ceremony_js = motion.split("packUnlock()")[0]
    refute_match(/NocheLiveAudio/, ceremony_js)
    gen = Rails.root.join("script/generate_sfx.rb").read
    assert_includes gen, "areverse,afade"
    quiz = Rails.root.join("app/javascript/controllers/quiz_controller.js").read
    %w[answer_tap question_change score_transfer crown_chime].each do |cue|
      refute_match(/play\?\.\("#{cue}"(?:,|\))/, quiz)
    end
    board = Rails.root.join("app/views/play/_quiz_board.html.erb").read
    refute_includes board, "quiz-sfx"
    quiz = Rails.root.join("app/javascript/controllers/quiz_controller.js").read
    assert_includes quiz, "releaseStreetAsk"
    assert_includes quiz, "releaseAsk"
    assert_includes quiz, "is-settled"
    stage = Rails.root.join("app/javascript/controllers/stage_controller.js").read
    assert_includes stage, "function releaseAsk("
    refute_includes stage, "turbo:before-stream-render"
    motion = Rails.root.join("app/javascript/controllers/motion_controller.js").read
    assert_includes motion.split("wrapStreet").last, "playFrom"
    study = Rails.root.join("app/javascript/controllers/study_run_controller.js").read
    assert_match(/correctValue \? "study_light" : "study_miss"/, study)
    assert_match(/play\?\.\("study_turn", 0\.5\)/, study)
    assert_includes study, 'dataset.studyRunRevealValue = "false"'
    assert_includes study, "window.clearTimeout(this.feedbackTimer)"
  end
end
