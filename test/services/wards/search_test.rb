require "test_helper"

class Wards::SearchTest < ActiveSupport::TestCase
  test "empty query returns only listed unidades, Benidorm first" do
    8.times { |i| extra_ward(i) }

    rows = Wards::Search.call(query: "")
    assert_equal [ wards(:demo) ], rows
    assert_not_includes rows.map(&:id), wards(:blank).id

    short = Wards::Search.call(query: "B")
    assert_equal rows.map(&:id), short.map(&:id)
  end

  test "listed extras still cap at six with Benidorm first" do
    8.times { |i| extra_ward(i, listed: true) }

    rows = Wards::Search.call(query: "")
    assert_operator rows.size, :<=, 6
    assert_equal wards(:demo), rows.first
    assert_not_includes rows.map(&:id), wards(:blank).id
  end

  test "place and code match listed ramas only" do
    extra_ward(1, listed: true)

    assert_includes Wards::Search.call(query: "Benidorm").map(&:id), wards(:demo).id
    assert_includes Wards::Search.call(query: "Alicante").map(&:id), wards(:demo).id
    assert_equal wards(:demo), Wards::Search.call(query: "RAMA").first
    assert_includes Wards::Search.call(query: "Valencia").map(&:name), "Rama Extra 1"
    assert_empty Wards::Search.call(query: "Madrid")
    assert_empty Wards::Search.call(query: "BLANK")
    assert_empty Wards::Search.call(query: "zzz")
  end
end
