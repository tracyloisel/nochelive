require "test_helper"

class Quizzes::DuelRaceTest < ActiveSupport::TestCase
  test "the closest comparable score outranks a scoreless rematch" do
    run = open_run(score: 15)
    target = duel_item(id: 801, other: people(:carmen_garcia), theirs: 91)
    rematch = duel_item(id: 802, other: people(:carmen_lopez), rematch: true)

    race = Quizzes::DuelRace.call(person: people(:pili), active: [ rematch, target ], run:)

    assert_equal target, race.item
    assert_equal :chasing, race.kind
    assert_equal 15, race.mine
    assert_equal 91, race.theirs
    assert_equal 77, race.crowns_needed
    assert race.provisional
  end

  test "a correct answer announces the moment the player passes a friend" do
    target = duel_item(id: 803, other: people(:carmen_garcia), theirs: 91)

    race = Quizzes::DuelRace.call(
      person: people(:pili), active: [ target ], run: open_run(score: 92), previous_score: 90
    )

    assert_equal :you_passed, race.kind
    assert race.event
  end

  test "a correct answer distinguishes a tie from an overtake" do
    target = duel_item(id: 804, other: people(:carmen_garcia), theirs: 91)

    race = Quizzes::DuelRace.call(
      person: people(:pili), active: [ target ], run: open_run(score: 91), previous_score: 88
    )

    assert_equal :you_tied, race.kind
  end

  test "a run opened before the duel is never projected into it" do
    target = duel_item(
      id: 805, other: people(:carmen_garcia), theirs: 91, accepted_at: 10.minutes.from_now
    )

    race = Quizzes::DuelRace.call(person: people(:pili), active: [ target ], run: open_run(score: 95))

    assert_equal :target, race.kind
    assert_nil race.mine
    assert_equal 91, race.theirs
  end

  test "remote progress detects ties and passes from the viewer perspective" do
    assert_equal :rival_tied, Quizzes::DuelRaceBroadcast.crossing_kind(
      previous_score: 88, current_score: 91, viewer_score: 91
    )
    assert_equal :rival_passed, Quizzes::DuelRaceBroadcast.crossing_kind(
      previous_score: 91, current_score: 94, viewer_score: 91
    )
    assert_equal :rival_progress, Quizzes::DuelRaceBroadcast.crossing_kind(
      previous_score: 40, current_score: 45, viewer_score: 91
    )
  end

  test "a finished duel uses a distinct official result state" do
    item = duel_item(id: 806, other: people(:carmen_garcia), theirs: 91)
    item.mine = 94

    race = Quizzes::DuelRace.call(
      person: people(:pili), active: [ item ], event: { duel_id: 806, kind: :official_ahead }
    )

    assert_equal :official_ahead, race.kind
    assert race.official
    refute race.provisional
    assert race.event
  end

  test "Campus can project a resolved duel for its one official live update" do
    duel = street_duels(:pili_vs_carmen)

    campus = Quizzes::DuelCampus.call(
      person: people(:pili), race_event: { duel_id: duel.id, kind: :official_ahead }
    )

    assert_equal duel, campus.race.item.duel
    assert_equal :official_ahead, campus.race.kind
    assert campus.race.official
  end

  private

    def open_run(score:)
      QuizRun.new(
        person: people(:pili), device_digest: "race-test", pack_id: "coronas",
        position: 4, score:, status: "open", opened_at: Time.current
      )
    end

    def duel_item(id:, other:, theirs: nil, rematch: false, accepted_at: 1.hour.ago)
      duel = StreetDuel.new(id:, accepted_at:, expires_at: 1.day.from_now)
      Quizzes::DuelCampus::DuelItem.new(
        duel:, other:, mine: nil, theirs:, state: theirs.nil? ? :ready : :your_turn,
        rematch:, rival_live: false
      )
    end
end
