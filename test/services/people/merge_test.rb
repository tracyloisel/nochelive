require "test_helper"

class People::MergeTest < ActiveSupport::TestCase
  test "moves players and devices onto the keeper then destroys the source" do
    night = game_sessions(:elias)
    keeper = people(:carmen_garcia)
    source = people(:carmen_lopez)
    player = Players::Join.call(
      night:,
      name: "Carmen",
      role: "participant",
      location: "room",
      device_token: "lopez-phone",
      person: source
    )

    People::Merge.call(keeper:, source:)

    assert_equal keeper, player.reload.person
    assert_not Person.exists?(source.id)
    assert PersonDevice.exists?(person: keeper, device_token: "lopez-phone")
  end

  test "refuses to merge fichas from another rama" do
    error = assert_raises(People::Error) do
      People::Merge.call(keeper: people(:pili), source: wards(:blank).people.create!(
        given_name: "Pili",
        avatar_key: "gato",
        favorite_year: 2001
      ))
    end
    assert_equal :ward, error.code
  end
end
