require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "normalizes maria and garcia" do
    person = wards(:blank).people.create!(
      given_name: "María",
      family_name: "García",
      avatar_key: "colibri",
      favorite_year: 33
    )
    assert_equal "maria", person.given_name_key
    assert_equal "garcia", person.family_name_key
    assert_equal "María García", person.display_name
  end

  test "on_device lists fichas for a tablet" do
    assert_includes Person.on_device("pili-tablet", wards(:demo)), people(:pili)
    assert_empty Person.on_device("pili-tablet", wards(:blank))
  end
end
