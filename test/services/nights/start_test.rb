require "test_helper"

class Nights::StartTest < ActiveSupport::TestCase
  test "creates a scheduled Noche and snapshots every ward team" do
    starts_at = 3.hours.from_now.change(usec: 0)
    ward = wards(:demo)
    night = Nights::Start.call(ward:, starts_at:, quiz_ids: %w[coronas moises])

    assert_equal starts_at, night.starts_at
    assert_equal starts_at + 1.hour, night.ends_at
    assert_equal %w[coronas moises], night.quiz_pack_ids
    assert_equal ward.ward_teams.order(:id).pluck(:id), night.teams.order(:ward_team_id).pluck(:ward_team_id).sort
  end

  test "rejects invalid quiz sequences" do
    assert_raises(ArgumentError) { Nights::Start.call(ward: wards(:blank), starts_at: 1.day.from_now, quiz_ids: []) }
    assert_raises(ArgumentError) { Nights::Start.call(ward: wards(:blank), starts_at: 1.day.from_now, quiz_ids: %w[missing]) }
    assert_raises(ArgumentError) { Nights::Start.call(ward: wards(:blank), starts_at: 1.day.from_now, quiz_ids: %w[coronas coronas]) }
  end
end
