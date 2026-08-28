require "test_helper"

class Platform::StatsTest < ActiveSupport::TestCase
  test "counts fichas not night seats and claimed wards not the empty directory" do
    stats = Platform::Stats.call

    assert_equal Person.count, stats.people
    assert_not_equal Player.count, stats.people
    assert_equal 1, stats.wards
    assert_equal 1, stats.countries
  end

  test "counts two countries and two locales from fichas" do
    brazil = extra_ward(11, country_code: "BR", country_name: "Brazil")
    brazil.people.create!(given_name: "Joao", avatar_key: "gato", favorite_year: 1998, locale: "pt-BR")
    people(:pili).update!(locale: "fr")

    stats = Platform::Stats.call
    by_code = stats.languages.index_by(&:code)

    assert_equal 2, stats.wards
    assert_equal 2, stats.countries
    assert_equal 2, by_code["es"].count
    assert_equal 1, by_code["pt-BR"].count
    assert_equal 1, by_code["fr"].count
    assert_equal 0, by_code["en"].count
    assert_in_delta 0.5, by_code["es"].share, 0.01
    assert_equal Locale::AVAILABLE, stats.languages.map(&:code)
  end

  test "counts street answers including guests and splits correct from wrong" do
    guest = quiz_runs(:crowd_milagros)
    QuizAnswer.create!(
      quiz_run: guest,
      device_digest: guest.device_digest,
      pack_id: guest.pack_id,
      question_id: "guest-wrong",
      choice_key: "no",
      correct: false
    )
    stats = Platform::Stats.call

    assert_equal QuizAnswer.count, stats.answers
    assert_equal QuizAnswer.where(correct: true).count, stats.correct
    assert_equal QuizAnswer.where(correct: false).count, stats.wrong
    assert_equal stats.correct + stats.wrong, stats.answers
    assert stats.answers >= 2
    assert_in_delta stats.correct.to_f / stats.answers, stats.path_share, 0.0001
  end

  test "counts every challenge and chapel teams not solo seats" do
    night = game_sessions(:david)
    before = Platform::Stats.call
    StreetDuel.create!(
      challenger_person: people(:pili),
      ward: wards(:demo),
      pack_id: "placas",
      token: "stats-duel-token",
      status: "pending",
      expires_at: 7.days.from_now
    )
    night.teams.create!(name: "SoloStats", emblem: "leon", solo: true)
    after_solo = Platform::Stats.call
    night.teams.create!(name: "SalaStats", emblem: "fuego")
    after_chapel = Platform::Stats.call

    assert_equal StreetDuel.count, after_solo.duels
    assert_equal before.duels + 1, after_solo.duels
    assert_equal GameSession.count, after_solo.nights
    assert_equal Team.chapel.count, after_chapel.teams
    assert_equal before.teams, after_solo.teams
    assert_equal before.teams + 1, after_chapel.teams
    assert_operator Team.solos.count, :>=, 2
  end

  test "counts each shared invitation once through the viral journey" do
    sent = street_duels(:pending_challenge)
    completed = street_duels(:pili_vs_carmen)
    [ sent, completed ].each do |duel|
      ViralEvent.create!(name: "invite_share_completed", device_digest: "stats-sender", street_duel: duel)
    end
    ViralEvent.create!(name: "invite_share_completed", device_digest: "stats-reminder", street_duel: sent)
    ViralEvent.create!(name: "invite_link_opened", device_digest: "stats-friend", street_duel: sent)

    stats = Platform::Stats.call

    assert_equal 2, stats.invitations_sent
    assert_equal 1, stats.invitations_opened
    assert_equal 1, stats.friends_joined
    assert_equal 1, stats.invitation_duels_completed
    assert_in_delta 0.5, stats.invitation_share, 0.001
  end

  test "invitation conversion is zero when nobody has shared" do
    ViralEvent.delete_all

    stats = Platform::Stats.call

    assert_equal 0, stats.invitations_sent
    assert_equal 0.0, stats.invitation_share
  end

  test "world top 20 sums each person's best pack and skips guests" do
    carmen = people(:carmen_garcia)
    worse = QuizRun.create!(
      device_digest: "stats-worse",
      person: carmen,
      pack_id: "milagros",
      position: 10,
      score: 10,
      status: "finished",
      opened_at: Time.current
    )
    placas = QuizRun.create!(
      device_digest: "stats-placas",
      person: carmen,
      pack_id: "placas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    stats = Platform::Stats.call
    row = stats.world.find { |entry| entry.person == carmen }

    assert_equal 1, row.rank
    assert_equal 120 + 88 + 40, row.score
    assert_equal "Carmen", row.person.given_name
    assert_equal wards(:demo), row.ward
    assert_nil(stats.world.find { |entry| entry.person.blank? })
    assert_operator stats.world.size, :<=, Platform::Stats::WORLD_LIMIT
    assert_not_equal worse.score + 120, row.score
    assert placas.finished?
  end

  test "world ranking skips profiles without a ward" do
    orphan = people(:pili)
    orphan.update!(ward: nil)
    QuizRun.create!(
      device_digest: "stats-orphan",
      person: orphan,
      pack_id: "orphan-pack",
      position: 10,
      score: 999,
      status: "finished",
      opened_at: Time.current
    )

    stats = Platform::Stats.call

    assert_not stats.world.any? { |row| row.person == orphan }
    assert_equal (1..stats.world.size).to_a, stats.world.map(&:rank)
  end
end
