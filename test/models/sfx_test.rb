require "test_helper"

class SfxTest < ActiveSupport::TestCase
  test "every declared cue resolves to a versioned public mp3" do
    Sfx::CUES.each do |cue|
      assert Sfx.file_for(cue), cue
      assert_match(%r{\A/sfx/#{Regexp.escape(cue)}\.mp3\?v=[a-f0-9]{12}\z}, Sfx.versioned_path_for(cue))
    end
  end
end
