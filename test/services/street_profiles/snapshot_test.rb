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
    visual_marks_before = person.scripture_marks.active.where.not(visual_style: "none").count
    person.scripture_marks.create!(
      reference: "ot/1-sam/16", locale: "fr", anchor_scope: "passage",
      visual_style: "highlight", color_key: "gold",
      start_verse: 1, start_offset: 2, end_verse: 2, end_offset: 14
    )
    person.scripture_marks.create!(
      reference: "ot/1-sam/16", locale: "fr", anchor_scope: "passage",
      visual_style: "none", start_verse: 13, start_offset: 0, end_verse: 13, end_offset: 20,
      bookmarked_at: Time.current
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
    assert_equal visual_marks_before + 1, snapshot.highlight_count
  end
end
