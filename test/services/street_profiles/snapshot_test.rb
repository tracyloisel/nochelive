require "test_helper"

class StreetProfiles::SnapshotTest < ActiveSupport::TestCase
  test "collects profile facts from their real sources" do
    person = people(:pili)
    run = quiz_runs(:pili_coronas)
    question = QuizDefinition.catalog.find_pack(run.pack_id).question_at(1)
    run.quiz_answers.create!(
      device_digest: run.device_digest,
      pack_id: run.pack_id,
      question_id: question.id,
      choice_key: question.correct_choice,
      correct: true,
      duration_ms: 1_500
    )

    snapshot = StreetProfiles::Snapshot.call(person:)

    assert_equal person, snapshot.person
    assert_equal person.ward, snapshot.ward
    assert_equal 95, snapshot.crowns
    assert_equal 2, snapshot.rank
    assert_equal 2, snapshot.ranked_people
    assert_equal "guerrero", snapshot.rank_key
    assert_equal 1, snapshot.packs_completed
    assert_equal 1, snapshot.challenge_wins
    assert_equal 1, snapshot.challenge_total
    assert_equal 0, snapshot.active_challenges
    assert_equal 1, snapshot.answer_count
    assert_equal 1, snapshot.correct_answer_count
  end
end
