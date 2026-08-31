require "test_helper"

class People::UpdateTest < ActiveSupport::TestCase
  test "ward admin can change the favorite year and name" do
    person = People::Update.call(
      person: people(:pili),
      given_name: "Pilar",
      family_name: "Sanz",
      avatar_key: "tortuga",
      favorite_year: 1991
    )
    assert_equal "Pilar", person.given_name
    assert_equal "Sanz", person.family_name
    assert_equal 1991, person.favorite_year
  end

  test "rejects a short year" do
    error = assert_raises(People::Error) do
      People::Update.call(
        person: people(:pili),
        given_name: "Pili",
        family_name: "",
        avatar_key: "tortuga",
        favorite_year: 33
      )
    end
    assert_equal :year, error.code
  end

  test "partial update preserves every absent canonical field" do
    person = people(:pili)
    original = person.attributes.slice("family_name", "avatar_key", "favorite_year")

    People::Update.call(person:, given_name: "Pilar")

    assert_equal "Pilar", person.given_name
    assert_equal original, person.attributes.slice("family_name", "avatar_key", "favorite_year")
  end
end
