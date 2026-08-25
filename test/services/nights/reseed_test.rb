require "test_helper"

class Nights::ReseedTest < ActiveSupport::TestCase
  test "wipes nights and opens a live Reyes y Profetas DEMO" do
    old = game_sessions(:david)
    assert old.playing?

    night = Nights::Reseed.call

    assert_equal "DEMO", night.code
    assert night.lobby?
    assert_equal "Reyes y Profetas", night.theme_title
    assert_equal "reyes_y_profetas", night.theme_file_id
    assert_equal 15, night.round_runs.count
    assert_nil GameSession.find_by(id: old.id)
    assert Ward.find_by(code: "RAMA")
    assert Person.find_by(given_name: "Carmen", family_name: "García")
  end
end
