require "test_helper"

class TabooTest < ActiveSupport::TestCase
  test "nabot guess matches and forbidden list is loaded" do
    round = GameDefinition.default.find_round("taboo_nabot")
    assert round.taboo?
    assert round.implemented?
    assert_equal %w[viña Acab Jezabel], round.forbidden
    assert_equal "B", round.remote_grade
    assert round.matches_guess?("Es la historia de Nabot")
    assert round.matches_guess?("NABOTH")
    assert_not round.matches_guess?("Daniel")
  end
end
