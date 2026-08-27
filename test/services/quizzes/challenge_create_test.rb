require "test_helper"

class Quizzes::ChallengeCreateTest < ActiveSupport::TestCase
  test "creates pending duel" do
    person = people(:pili)
    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      device_digest: GameSession.digest_token("create-pending")
    )
    assert result.duel.pending?
    assert_equal "placas", result.duel.pack_id
    assert_equal "/desafio/#{result.duel.token}", result.share_url
  end

  test "reuses an open duel for the same pack" do
    person = people(:pili)
    first = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      device_digest: GameSession.digest_token("reuse-open")
    )
    second = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      device_digest: GameSession.digest_token("reuse-open")
    )
    assert_equal first.duel.id, second.duel.id
  end

  test "finished run marks the challenger done" do
    person = people(:pili)
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("create-done"),
      person:,
      pack_id: "placas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: 1.hour.ago
    )
    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      run:
    )
    assert result.duel.challenger_done?
    assert_equal 55, result.duel.challenger_score
    assert_equal run.id, result.duel.challenger_run_id
  end

  test "rejects an unknown pack" do
    person = people(:pili)
    assert_raises(ArgumentError) do
      Quizzes::ChallengeCreate.call(
        challenger_person: person,
        ward: person.ward,
        pack_id: "no-such-pack"
      )
    end
  end

  test "named duel sets the opponent and needs a finished run" do
    person = people(:pili)
    carmen = people(:carmen_garcia)
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("named-create"),
      person:,
      pack_id: "placas",
      position: 10,
      score: 61,
      status: "finished",
      opened_at: 1.hour.ago
    )
    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      run:,
      opponent_person: carmen
    )
    assert_equal carmen.id, result.duel.opponent_person_id
    assert result.duel.challenger_done?
    assert_equal 61, result.duel.challenger_score
  end

  test "named reuse keeps an anonymous open duel untouched" do
    person = people(:pili)
    carmen = people(:carmen_garcia)
    anon = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      device_digest: GameSession.digest_token("anon-open")
    )
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("named-reuse"),
      person:,
      pack_id: "placas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: 1.hour.ago
    )
    named = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      run:,
      opponent_person: carmen
    )
    refute_equal anon.duel.id, named.duel.id
    assert_nil anon.duel.reload.opponent_person_id
    assert_equal carmen.id, named.duel.opponent_person_id

    again = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      run:,
      opponent_person: carmen
    )
    assert_equal named.duel.id, again.duel.id
  end

  test "denies self and a person outside the stake but needs no finished score" do
    person = people(:pili)
    carmen = people(:carmen_garcia)
    outsider = wards(:blank).people.create!(given_name: "Fora", avatar_key: "gato", favorite_year: 2011)
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("named-denied"),
      person:,
      pack_id: "placas",
      position: 10,
      score: 20,
      status: "finished",
      opened_at: 1.hour.ago
    )

    error = assert_raises(Quizzes::ChallengeCreate::Denied) do
      Quizzes::ChallengeCreate.call(
        challenger_person: person,
        ward: person.ward,
        pack_id: "placas",
        run:,
        opponent_person: person
      )
    end
    assert_equal :self, error.code

    error = assert_raises(Quizzes::ChallengeCreate::Denied) do
      Quizzes::ChallengeCreate.call(
        challenger_person: person,
        ward: person.ward,
        pack_id: "placas",
        run:,
        opponent_person: outsider
      )
    end
    assert_equal :stake, error.code

    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "placas",
      device_digest: GameSession.digest_token("named-no-score"),
      opponent_person: carmen
    )
    assert result.duel.challenger_run.open?
    assert_equal result.duel.id, result.duel.challenger_run.street_duel_id
  end

  test "allows a rematch after the previous duel resolved" do
    person = people(:pili)
    carmen = people(:carmen_garcia)
    run = quiz_runs(:pili_coronas)
    result = Quizzes::ChallengeCreate.call(
      challenger_person: person,
      ward: person.ward,
      pack_id: "coronas",
      run:,
      opponent_person: carmen
    )
    refute_equal street_duels(:pili_vs_carmen).id, result.duel.id
  end
end
