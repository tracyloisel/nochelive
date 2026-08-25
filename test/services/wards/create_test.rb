require "test_helper"

class Wards::CreateTest < ActiveSupport::TestCase
  test "creates a rama with a presenter token" do
    ward = Wards::Create.call(name: "Rama Valencia", city: "Valencia", emblem: "leon")
    assert_equal "Rama Valencia", ward.name
    assert_equal "Valencia", ward.city
    assert_equal "leon", ward.emblem
    assert_not ward.listed?
    assert ward.presenter_token.present?
    assert ward.presenter_token_matches?(ward.presenter_token)
  end

  test "lists the first rama when the directory is empty" do
    Ward.update_all(listed: false)
    ward = Wards::Create.call(name: "Rama Valencia")
    assert ward.listed?
  end

  test "rejects a blank name" do
    error = assert_raises(People::Error) { Wards::Create.call(name: "  ") }
    assert_equal :blank, error.code
  end
end
