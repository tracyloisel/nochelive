require "test_helper"

class SfxTest < ActiveSupport::TestCase
  test "every named cue has an original recording and no scattered paths in models" do
    Sfx::CUES.each do |name|
      path = Rails.root.join("public/sfx/#{name}.wav")
      assert path.exist?, "missing #{name}.wav"
      assert Sfx.known?(name)
      assert_equal "/sfx/#{name}.wav", Sfx.path_for(name)
    end
    assert_equal Sfx::CUES.size, Sfx.catalog.size
    assert_not Sfx.known?("nope")
    assert_nil Sfx.path_for("nope")
  end
end
