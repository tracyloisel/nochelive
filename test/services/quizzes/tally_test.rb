require "test_helper"

class Quizzes::TallyTest < ActiveSupport::TestCase
  test "counts the first vote per device" do
    pack = "coronas"
    qid = "ungio_david"
    first = GameSession.digest_token("tally-first")
    second = GameSession.digest_token("tally-second")
    run_a = QuizRun.create!(device_digest: first, pack_id: pack, position: 1, score: 0, status: "open", opened_at: Time.current)
    run_b = QuizRun.create!(device_digest: second, pack_id: pack, position: 1, score: 0, status: "open", opened_at: Time.current)
    Quizzes::Submit.call(run: run_a, choice_key: "samuel")
    Quizzes::Submit.call(run: run_b, choice_key: "saul")

    rows = Quizzes::Tally.call(pack_id: pack, question_id: qid)
    samuel = rows.find { |row| row.key == "samuel" }
    saul = rows.find { |row| row.key == "saul" }
    assert samuel.correct
    assert_equal 1, samuel.count
    assert_equal 1, saul.count
    assert_equal 50, samuel.percent

    replay = QuizRun.create!(device_digest: first, pack_id: pack, position: 1, score: 0, status: "open", opened_at: Time.current)
    Quizzes::Submit.call(run: replay, choice_key: "saul")
    again = Quizzes::Tally.call(pack_id: pack, question_id: qid)
    assert_equal 1, again.find { |row| row.key == "samuel" }.count
    assert_equal 1, again.find { |row| row.key == "saul" }.count
  end
end
