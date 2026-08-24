require "test_helper"

class People::RegisterTest < ActiveSupport::TestCase
  setup { @ward = wards(:demo) }

  test "creates a ficha and attaches the device" do
    person = People::Register.call(
      ward: @ward,
      given_name: "Lucía",
      family_name: "",
      avatar_key: "loro",
      favorite_year: 2010,
      device_token: "dev-lucia"
    )
    assert_equal "lucia", person.given_name_key
    assert_equal 2010, person.favorite_year
    assert PersonDevice.exists?(person:, device_token: "dev-lucia")
  end

  test "second carmen without apellido is rejected" do
    error = assert_raises(People::Error) do
      People::Register.call(
        ward: @ward,
        given_name: "Carmen",
        family_name: "",
        avatar_key: "gato",
        favorite_year: 1492,
        device_token: "dev"
      )
    end
    assert_equal :family, error.code
  end

  test "second carmen with apellido is kept" do
    person = People::Register.call(
      ward: @ward,
      given_name: "Carmen",
      family_name: "Ruiz",
      avatar_key: "gato",
      favorite_year: 1492,
      device_token: "dev"
    )
    assert_equal "ruiz", person.family_name_key
  end

  test "same ficha tuple is a claim not a duplicate" do
    error = assert_raises(People::Error) do
      People::Register.call(
        ward: @ward,
        given_name: "Carmen",
        family_name: "García",
        avatar_key: "delfin",
        favorite_year: 1833,
        device_token: "dev"
      )
    end
    assert_equal :taken, error.code
  end

  test "same avatar and apellido with another year is a second ficha" do
    person = People::Register.call(
      ward: @ward,
      given_name: "Carmen",
      family_name: "García",
      avatar_key: "delfin",
      favorite_year: 1830,
      device_token: "dev"
    )
    assert_not_equal people(:carmen_garcia).id, person.id
    assert_equal 1830, person.favorite_year
  end

  test "rejects a year that is not four digits" do
    error = assert_raises(People::Error) do
      People::Register.call(
        ward: @ward,
        given_name: "Noa",
        family_name: "",
        avatar_key: "gato",
        favorite_year: 33,
        device_token: "dev"
      )
    end
    assert_equal :year, error.code
  end
end
