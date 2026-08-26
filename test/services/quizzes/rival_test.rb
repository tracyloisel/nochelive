require "test_helper"

class Quizzes::RivalTest < ActiveSupport::TestCase
  test "finds the player directly above even when rank is beyond mini board limit" do
    ward = wards(:blank)
    people = Array.new(12) do |index|
      ward.people.create!(
        given_name: "Rival#{index}",
        avatar_key: Player::AVATARS[index % Player::AVATARS.size],
        favorite_year: 2005 + index
      )
    end
    people.each_with_index do |person, index|
      QuizRun.create!(
        device_digest: "rival-#{index}",
        person:,
        pack_id: "coronas",
        position: 10,
        score: (index + 1) * 5,
        status: "finished",
        opened_at: Time.current
      )
    end
    target = people[7]

    rival = Quizzes::Rival.call(ward:, person: target, pack_id: "coronas")

    assert_equal people[8], rival.person
    assert_equal 4, rival.rank
    assert_equal 45, rival.score
    assert_equal 5, rival.gap
    assert_equal 5, rival.pack_gap
    assert_equal 10, rival.others
    assert_not rival.live
  end

  test "marks the chase rival live and counts the rest of the board" do
    ward = wards(:blank)
    lead = ward.people.create!(given_name: "Lead", avatar_key: Player::AVATARS.first, favorite_year: 2001)
    chase = ward.people.create!(given_name: "Chase", avatar_key: Player::AVATARS.second, favorite_year: 2002)
    extra = ward.people.create!(given_name: "Extra", avatar_key: Player::AVATARS.third, favorite_year: 2003)
    QuizRun.create!(device_digest: "lead-live", person: lead, pack_id: "coronas", position: 10, score: 40, status: "finished", opened_at: Time.current)
    QuizRun.create!(device_digest: "chase-live", person: chase, pack_id: "coronas", position: 10, score: 80, status: "finished", opened_at: Time.current)
    QuizRun.create!(device_digest: "extra-live", person: extra, pack_id: "coronas", position: 10, score: 20, status: "finished", opened_at: Time.current)
    PersonDevice.create!(person: chase, device_token: "chase-live-token", last_seen_at: Time.current)

    rival = Quizzes::Rival.call(ward:, person: lead, pack_id: "coronas")

    assert_equal chase, rival.person
    assert rival.live
    assert_equal 1, rival.others
  end

  test "hides the others count when the board is just you and one ghost" do
    ward = wards(:blank)
    lead = ward.people.create!(given_name: "Lead", avatar_key: Player::AVATARS.first, favorite_year: 2001)
    chase = ward.people.create!(given_name: "Chase", avatar_key: Player::AVATARS.second, favorite_year: 2002)
    QuizRun.create!(device_digest: "pair-lead", person: lead, pack_id: "coronas", position: 10, score: 40, status: "finished", opened_at: Time.current)
    QuizRun.create!(device_digest: "pair-chase", person: chase, pack_id: "coronas", position: 10, score: 80, status: "finished", opened_at: Time.current)

    rival = Quizzes::Rival.call(ward:, person: lead, pack_id: "coronas")

    assert_equal chase, rival.person
    assert_equal 0, rival.others
    assert_not rival.live
  end

  test "a ward without a signed-in person still names a rival" do
    rival = Quizzes::Rival.call(ward: wards(:demo), person: nil, pack_id: "coronas")
    assert rival.person
    assert rival.score.positive?
  end

  test "falls back to the nearest other player when you lead" do
    ward = wards(:blank)
    leader = ward.people.create!(given_name: "Lead", avatar_key: Player::AVATARS.first, favorite_year: 2001)
    chase = ward.people.create!(given_name: "Chase", avatar_key: Player::AVATARS.second, favorite_year: 2002)
    QuizRun.create!(device_digest: "lead-run", person: leader, pack_id: "coronas", position: 10, score: 80, status: "finished", opened_at: Time.current)
    QuizRun.create!(device_digest: "chase-run", person: chase, pack_id: "coronas", position: 10, score: 50, status: "finished", opened_at: Time.current)

    rival = Quizzes::Rival.call(ward:, person: leader, pack_id: "coronas")

    assert_equal chase, rival.person
    assert_equal 2, rival.rank
    assert_equal 50, rival.score
    assert_operator rival.gap, :<, 0
  end
end
