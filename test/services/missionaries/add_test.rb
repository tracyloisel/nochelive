require "test_helper"

class Missionaries::AddTest < ActiveSupport::TestCase
  test "adds a missionary name to the night" do
    night = game_sessions(:elias)
    missionary = Missionaries::Add.call(night:, name: "Élder Soto")
    assert_equal "Élder Soto", missionary.name
    assert_includes night.missionaries.reload.map(&:name), "Élder Soto"
  end

  test "rejects a blank name" do
    error = assert_raises(People::Error) do
      Missionaries::Add.call(night: game_sessions(:elias), name: "  ")
    end
    assert_equal :name, error.code
  end
end
