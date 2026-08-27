require "test_helper"

class Huds::PresentTest < ActiveSupport::TestCase
  test "quiz HUD on a finished pack shows all dots last gain and end combo" do
    digest = GameSession.digest_token("hud-ceremony")
    person = people(:pili)
    run = Quizzes::Draw.call(device_digest: digest, person_id: person.id).run
    10.times do
      Quizzes::Submit.call(run: run.reload, choice_key: run.question.correct_choice)
      Quizzes::Advance.call(run: run.reload)
    end
    street = Quizzes::Draw.frame(run.reload, ward: person.ward)
    bar = Huds::Present.quiz(
      person:,
      pack: street.pack,
      run: street.run,
      street:,
      question: street.question,
      combo: Quizzes::HitStreak.call(run: street.run)
    )

    assert bar.quiz?
    assert bar.done?
    assert_equal 10, bar.progress_n
    assert_equal 10, bar.progress_total
    assert_equal Array.new(10, "is-done"), bar.dots
    assert bar.last_gain.positive?
    assert_equal street.run.score - bar.last_gain, bar.score
    assert_equal 10, bar.combo.count
    refute bar.combo.grew
  end

  test "quiz HUD on an open ask does not print last-hit gain" do
    digest = GameSession.digest_token("hud-ask")
    run = Quizzes::Draw.call(device_digest: digest).run
    street = Quizzes::Draw.frame(run)
    bar = Huds::Present.quiz(
      person: nil,
      pack: street.pack,
      run:,
      street:,
      question: street.question
    )

    refute bar.done?
    assert_nil bar.last_gain
    assert_equal 1, bar.progress_n
    assert_includes bar.dots, "is-now"
  end
end
