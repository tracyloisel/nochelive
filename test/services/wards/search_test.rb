require "test_helper"

class Wards::SearchTest < ActiveSupport::TestCase
  test "empty query does not dump listed ramas" do
    8.times { |i| extra_ward(i, listed: true) }

    rows = Wards::Search.call(query: "").wards
    assert_empty rows
    assert_not_includes Wards::Search.call(query: "").wards.map(&:id), wards(:blank).id

    short = Wards::Search.call(query: "B").wards
    assert_empty short

    search = Wards::Search.call(query: "")
    assert search.featured?
    assert_not search.nearby?
  end

  test "place and code match listed ramas only" do
    extra_ward(1, listed: true)

    assert_includes Wards::Search.call(query: "Benidorm").wards.map(&:id), wards(:demo).id
    assert_includes Wards::Search.call(query: "Alicante").wards.map(&:id), wards(:demo).id
    assert_equal wards(:demo), Wards::Search.call(query: "RAMA").wards.first
    assert_includes Wards::Search.call(query: "Valencia").wards.map(&:name), "Rama Extra 1"
    assert_empty Wards::Search.call(query: "Madrid").wards
    assert_empty Wards::Search.call(query: "BLANK").wards
    assert_empty Wards::Search.call(query: "zzz").wards
  end

  test "does not eager-load nights on the picker" do
    ward = Wards::Search.call(query: "Benidorm").wards.first
    assert_not ward.association(:game_sessions).loaded?
  end

  test "merges locator hits that are not stored yet" do
    Wards::QueryLocator.forced_hits = [
      Wards::QueryLocator.attrs_from(JSON.parse(file_fixture("maps_ward_madrid.json").read).first)
    ]

    rows = Wards::Search.call(query: "Madrid").wards
    assert_equal 1, rows.size
    hit = rows.first
    assert_not hit.persisted?
    assert_equal "Madrid 1st Ward", hit.name
    assert_equal "999001", hit.church_unit_id
    assert_equal "Calle del Prado 1", hit.chapel_address
    assert_nil hit.code
  end

  test "does not show a second Benidorm when the locator also returns the chapel" do
    Wards::QueryLocator.forced_hits = [
      Wards::QueryLocator.attrs_from(JSON.parse(file_fixture("maps_ward_benidorm.json").read).first)
    ]

    rows = Wards::Search.call(query: "Benidorm").wards
    assert_equal [ wards(:demo).id ], rows.map(&:id)
  end

  test "nearby coords return one suggested rama from the locator" do
    Wards::QueryLocator.forced_near = [
      Wards::QueryLocator.attrs_from(JSON.parse(file_fixture("maps_ward_madrid.json").read).first)
    ]

    search = Wards::Search.call(query: "", latitude: 40.42, longitude: -3.70)
    assert search.nearby?
    assert_equal 1, search.wards.size
    hit = search.wards.first
    assert hit.featured?
    assert_equal "Madrid 1st Ward", hit.name
    assert_equal "999001", hit.church_unit_id
    assert_equal "Calle del Prado 1", hit.chapel_address
  end

  test "nearby Benidorm merges into RAMA" do
    Wards::QueryLocator.forced_near = [
      Wards::QueryLocator.attrs_from(JSON.parse(file_fixture("maps_ward_benidorm.json").read).first)
    ]

    rows = Wards::Search.call(query: "", latitude: 38.54, longitude: -0.12).wards
    assert_equal [ wards(:demo) ], rows
  end
end
