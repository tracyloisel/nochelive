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
end
