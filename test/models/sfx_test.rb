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
    assert_not Sfx.pulse_without_player?("buzz")
  end
end
