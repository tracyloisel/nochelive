require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "Noche title and artwork come from the first quiz pack" do
    night = game_sessions(:david)

    assert_equal night.primary_quiz_pack.copy(:title), night_title(night)
    assert_equal street_still_src(night.primary_quiz_pack.question_at(1)), night_still_src(night)
  end

  test "every Noche links to its canonical URL including finished nights" do
    assert_equal night_path(game_sessions(:david).code), home_night_path_for(game_sessions(:david))
    assert_equal night_path(game_sessions(:cerrada).code), home_night_path_for(game_sessions(:cerrada))
  end
end
