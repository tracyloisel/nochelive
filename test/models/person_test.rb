require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "normalizes maria and garcia" do
    person = wards(:blank).people.create!(
      given_name: "María",
      family_name: "García",
      avatar_key: "colibri",
      favorite_year: 1833
    )
    assert_equal "maria", person.given_name_key
    assert_equal "garcia", person.family_name_key
    assert_equal "María García", person.display_name
    assert Person.valid_year?(1833)
    assert_not Person.valid_year?(33)
    assert_not Person.valid_year?(10_000)
  end

  test "on_device lists fichas for a tablet" do
    assert_includes Person.on_device("pili-tablet", wards(:demo)), people(:pili)
    assert_empty Person.on_device("pili-tablet", wards(:blank))
  end

  test "validates every canonical profile field at the model boundary" do
    person = valid_person

    person.given_name = nil
    assert_not person.valid?
    assert person.errors.added?(:given_name, :blank)

    person = valid_person(given_name: "A" * (Person::NAME_MAX + 1))
    assert_not person.valid?
    assert person.errors.added?(:given_name, :too_long, count: Person::NAME_MAX)

    person = valid_person(family_name: "B" * (Person::NAME_MAX + 1))
    assert_not person.valid?
    assert person.errors.added?(:family_name, :too_long, count: Person::NAME_MAX)

    person = valid_person(avatar_key: "dragon")
    assert_not person.valid?
    assert person.errors.added?(:avatar_key, :inclusion, value: "dragon")

    person = valid_person(locale: "de")
    assert_not person.valid?
    assert person.errors.added?(:locale, :inclusion, value: "de")
  end

  test "normalizes names and canonical enum fields before validation" do
    person = valid_person(
      given_name: "  María   José  ",
      family_name: "  O’Neill  ",
      avatar_key: " colibri ",
      locale: " fr "
    )

    assert_predicate person, :valid?
    assert_equal "María José", person.given_name
    assert_equal "O’Neill", person.family_name
    assert_equal "mariajose", person.given_name_key
    assert_equal "oneill", person.family_name_key
    assert_equal "colibri", person.avatar_key
    assert_equal "fr", person.locale
  end

  test "rejects control characters in player names" do
    person = valid_person(given_name: "Ana\nMaría")

    assert_not person.valid?
    assert person.errors.added?(:given_name, :invalid, value: "Ana\nMaría")
  end

  test "favorite year is optional four digit history and never future" do
    assert_predicate valid_person(favorite_year: nil), :valid?

    too_old = valid_person(favorite_year: Person::YEAR_MIN - 1)
    assert_not too_old.valid?
    assert_includes too_old.errors.details[:favorite_year].pluck(:error), :greater_than_or_equal_to
    assert_not too_old.errors.added?(:favorite_year, :future)

    future = valid_person(favorite_year: Time.current.year + 1)
    assert_not future.valid?
    assert future.errors.added?(:favorite_year, :future)
  end

  test "last ward team must belong to the profile ward" do
    other_team = wards(:blank).ward_teams.create!(
      name: "Otra familia", emblem: "paloma"
    )
    person = people(:pili)
    person.last_ward_team = other_team

    assert_not person.valid?
    assert person.errors.added?(:last_ward_team, :invalid)

    person.last_ward_team = ward_teams(:leones_ward_team)
    assert_predicate person, :valid?
  end

  test "changing or removing the ward clears the remembered team" do
    person = people(:pili)

    person.ward = nil

    assert_predicate person, :valid?
    assert_nil person.last_ward_team
  end

  test "homonyms remain allowed for progressive family profiles" do
    original = people(:carmen_garcia)
    duplicate = valid_person(
      ward: original.ward,
      given_name: original.given_name,
      family_name: original.family_name,
      avatar_key: original.avatar_key,
      favorite_year: original.favorite_year
    )

    assert_predicate duplicate, :valid?
  end

  private

    def valid_person(**attributes)
      Person.new({
        ward: wards(:demo),
        given_name: "Lucía",
        family_name: "Ruiz",
        avatar_key: "colibri",
        favorite_year: 2010,
        locale: "es"
      }.merge(attributes))
    end
end
