require "test_helper"

class People::RecognizeTest < ActiveSupport::TestCase
  test "lists carmen homonyms without showing years when avatar and apellido differ" do
    cards = People::Recognize.call(ward: wards(:demo), given_name: "Carmen")
    assert_equal 2, cards.size
    assert cards.none?(&:show_year)
  end

  test "shows year only when avatar and apellido collide" do
    People::Register.call(
      ward: wards(:demo),
      given_name: "Carmen",
      family_name: "García",
      avatar_key: "delfin",
      favorite_year: 1830,
      device_token: "x"
    )
    cards = People::Recognize.call(ward: wards(:demo), given_name: "Carmen")
    garcias = cards.select { |card| card.person.family_name_key == "garcia" }
    assert_equal 2, garcias.size
    assert garcias.all?(&:show_year)
    lopez = cards.find { |card| card.person.family_name_key == "lopez" }
    assert_not lopez.show_year
  end
end
