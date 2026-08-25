require "test_helper"

class Nights::FeedTest < ActiveSupport::TestCase
  test "lists upcoming nights this fortnight and the last finished ones" do
    feed = Nights::Feed.call
    codes = feed[:upcoming].map(&:code)
    assert_includes codes, "DAVID"
    assert_includes codes, "ELIAS"
    refute_includes codes, "QUIT"
    assert_equal [ "QUIT" ], feed[:past].map(&:code)
  end

  test "hides nights from unlisted ramas" do
    night = Nights::Start.call(ward: wards(:blank))
    feed = Nights::Feed.call
    refute_includes feed[:upcoming].map(&:code), night.code
  end
end
