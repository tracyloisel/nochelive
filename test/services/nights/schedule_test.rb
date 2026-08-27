require "test_helper"

class Nights::ScheduleTest < ActiveSupport::TestCase
  test "opens a lobby night at the given hour with named elders" do
    starts = Time.zone.parse("2026-08-29 19:00")
    night = Nights::Schedule.call(
      ward: wards(:blank),
      starts_at: starts,
      theme_id: "reyes_y_profetas",
      missionary_names: [ "Élder Oxxon", "Élder Manning" ]
    )

    assert night.lobby?
    assert_equal wards(:blank), night.ward
    assert_equal starts, night.starts_at
    assert_equal "kings_and_prophets", night.theme_id
    assert_equal "Reyes y Profetas", night.theme_title
    assert_equal [ "Élder Oxxon", "Élder Manning" ], night.missionaries.order(:id).pluck(:name)
  end

  test "updates the rama lobby instead of hijacking a playing night" do
    playing = game_sessions(:david)
    starts = Time.zone.parse("2026-08-29 19:00")
    night = Nights::Schedule.call(
      ward: wards(:demo),
      starts_at: starts,
      missionary_names: [ "Élder Oxxon" ]
    )

    assert_equal game_sessions(:elias).id, night.id
    assert_equal starts, night.starts_at
    assert playing.reload.playing?
    assert_includes night.missionaries.pluck(:name), "Élder Oxxon"
  end

  test "does not reuse a leftover lobby from last week" do
    game_sessions(:elias).update!(starts_at: 5.days.ago)
    starts = Time.zone.parse("2026-08-29 19:00")
    night = Nights::Schedule.call(
      ward: wards(:demo),
      starts_at: starts,
      missionary_names: [ "Élder Oxxon" ]
    )

    refute_equal game_sessions(:elias).id, night.id
    assert night.lobby?
    assert_equal starts, night.starts_at
  end

  test "is idempotent on missionary names" do
    starts = Time.zone.parse("2026-08-29 19:00")
    first = Nights::Schedule.call(
      ward: wards(:blank),
      starts_at: starts,
      missionary_names: [ "Élder Manning" ]
    )
    second = Nights::Schedule.call(
      ward: wards(:blank),
      starts_at: starts + 1.hour,
      missionary_names: [ "Élder Manning" ]
    )

    assert_equal first.id, second.id
    assert_equal 1, second.missionaries.where(name: "Élder Manning").count
    assert_equal starts + 1.hour, second.starts_at
  end
end
