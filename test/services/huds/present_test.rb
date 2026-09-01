require "test_helper"

class Huds::PresentTest < ActiveSupport::TestCase
  test "Home can keep identity in the HUD without repeating hero progress" do
    player = Hubs::Screen::Player.new(
      name: "Pili",
      rank_key: "explorer",
      level: 2,
      xp_now: 120,
      xp_next: 200,
      xp_progress: 60,
      crowns: 120,
      streak: 3,
      guest: false
    )
    hero = Hubs::Screen::Hero.new(title: "La puerta estrecha", step_n: 4, step_total: 10)
    screen = Hubs::Screen::Result.new(player:, hero:)

    bar = Huds::Present.from_screen(screen:, show_adventure: false)

    assert_equal "Pili", bar.name
    assert_equal 120, bar.crowns
    assert_nil bar.pack_title
    assert_equal 0, bar.progress_n
    assert_equal 0, bar.progress_total
    assert_empty bar.dots
  end

  test "Home hides empty crown and streak values without hiding real progress" do
    player = Hubs::Screen::Player.new(
      name: "Pili",
      rank_key: "explorer",
      level: 1,
      xp_progress: 0,
      crowns: 0,
      streak: 0,
      guest: false
    )
    screen = Hubs::Screen::Result.new(player:, hero: Hubs::Screen::Hero.new)

    editorial_bar = Huds::Present.from_screen(
      screen:,
      show_adventure: false,
      show_empty_stats: false
    )
    regular_bar = Huds::Present.from_screen(screen:)

    assert_nil editorial_bar.crowns
    assert_nil editorial_bar.streak
    assert_equal 0, regular_bar.crowns
    assert_equal 0, regular_bar.streak
  end

  test "street HUD keeps a player's crowns without an active ward" do
    person = people(:pili)
    crowns = Quizzes::Complete.total_best(person)

    assert_predicate crowns, :positive?
    bar = Huds::Present.call(person:, ward: nil, device_digest: GameSession.digest_token("hud-without-ward"))

    assert_equal crowns, bar.crowns
  end

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
