require "test_helper"
require "view_component/test_case"

class Hud::BarComponentTest < ViewComponent::TestCase
  test "guest street HUD invites anyone to save progress with a profile" do
    bar = Huds::Present::Result.new(kind: :street, guest: true, dots: [])
    render_inline(Hud::BarComponent.new(bar:))

    assert_selector ".quiz-hud.is-guest[data-hud-theme='celestial-light'][data-controller~='hud-surface']"
    assert_selector ".quiz-hud-avatar.is-guest .picto-profile-spark"
    assert_text I18n.t("hub.guest_invite")
    assert_text I18n.t("hub.guest_in_ward")
    assert_selector "a.quiz-hud-who.is-guest[href*='fresh=1']"
    assert_selector ".quiz-hud-guest-go .picto-arrow"
    assert_no_selector ".quiz-hud-cta"
    assert_no_selector ".quiz-hud-rail"
    assert_no_selector ".quiz-hud-score"
  end

  test "HUD exposes only the two canonical celestial themes" do
    bar = Huds::Present::Result.new(kind: :street, guest: true, dots: [])

    render_inline(Hud::BarComponent.new(bar:, theme: "dark"))
    assert_selector ".quiz-hud[data-hud-theme='celestial-dark']"

    render_inline(Hud::BarComponent.new(bar:, theme: "celestial-light"))
    assert_selector ".quiz-hud[data-hud-theme='celestial-light']"

    render_inline(Hud::BarComponent.new(bar:, theme: "sepia"))
    assert_selector ".quiz-hud[data-hud-theme='celestial-light']"
  end

  test "signed-in street HUD keeps player state without repeating adventure progress" do
    bar = Huds::Present::Result.new(
      kind: :street,
      guest: false,
      name: "Pilar",
      rank_key: "leyenda",
      level: 6,
      xp_now: 382,
      xp_next: 500,
      xp_progress: 64,
      pack_title: "Coronas",
      progress_n: 2,
      progress_total: 10,
      dots: [ "is-done", "is-now" ] + ([ "is-next" ] * 8),
      crowns: 382,
      streak: 2
    )
    render_inline(Hud::BarComponent.new(bar:))

    assert_selector "a.quiz-hud-who[href='/']"
    assert_selector ".quiz-hud-name", text: "Pilar"
    assert_selector ".quiz-hud-rank", text: I18n.t("ranks.leyenda")
    assert_no_selector ".quiz-hud > .quiz-hud-level"
    assert_selector ".quiz-hud-who .quiz-hud-level", text: "6"
    assert_no_selector ".quiz-hud-pack .quiz-hud-level"
    assert_selector ".quiz-hud-xp[role=progressbar][aria-valuenow='64']"
    assert_selector ".quiz-hud[data-controller~='hud-surface']"
    assert_no_selector ".quiz-hud-pack"
    assert_no_selector ".quiz-hud-title", text: "Coronas"
    assert_no_selector ".quiz-hud-progress"
    assert_no_selector ".quiz-hud-rail"
    assert_selector ".quiz-hud-score", text: /382/
    assert_selector ".quiz-hud-streak-num", text: "2"
    assert_selector ".quiz-hud-menu"
    assert_no_selector ".quiz-hud-cta"
  end

  test "editorial street HUD omits empty crown and streak counters" do
    bar = Huds::Present::Result.new(
      kind: :street,
      guest: false,
      name: "Pilar",
      rank_key: "explorador",
      level: 1,
      xp_progress: 0,
      dots: [],
      crowns: nil,
      streak: nil
    )

    render_inline(Hud::BarComponent.new(bar:))

    assert_selector ".quiz-hud-name", text: "Pilar"
    assert_no_selector ".quiz-hud-stats"
    assert_no_selector ".quiz-hud-score"
    assert_no_selector ".quiz-hud-streak"
  end

  test "editorial street HUD keeps explicit zero crown and streak values" do
    bar = Huds::Present::Result.new(
      kind: :street,
      guest: false,
      name: "Pilar",
      rank_key: "explorador",
      level: 1,
      xp_progress: 0,
      dots: [],
      crowns: 0,
      streak: 0
    )

    render_inline(Hud::BarComponent.new(bar:))

    assert_selector ".quiz-hud-score", text: "0"
    assert_selector ".quiz-hud-streak.is-idle[data-tier='idle'] .quiz-hud-streak-num", text: "0"
  end

  test "quiz HUD keeps crown score targets and the same living fire as the payoff" do
    bar = Huds::Present::Result.new(
      kind: :quiz,
      guest: false,
      name: "Pilar",
      rank_key: "leyenda",
      level: 1,
      pack_title: "Coronas",
      progress_n: 2,
      progress_total: 10,
      dots: [ "is-done", "is-now" ] + ([ "is-next" ] * 8),
      score: 5,
      combo: Huds::Present::Combo.new(count: 2, tier: "glow", broke: false, grew: true, shout_key: "two")
    )
    render_inline(Hud::BarComponent.new(bar:))

    assert_selector ".quiz-hud.is-quiz"
    assert_no_selector ".quiz-hud[data-controller~='hud-surface']"
    assert_selector ".quiz-hud-title", text: "Coronas"
    assert_selector ".quiz-hud-progress", text: I18n.t("quiz.progress", n: 2, total: 10)
    assert_selector ".quiz-hud-dot.is-done", count: 1
    assert_selector ".quiz-hud-dot.is-now", count: 1
    assert_no_selector ".quiz-hud > .quiz-hud-level"
    assert_selector ".quiz-hud-name .quiz-hud-level", text: "1"
    assert_no_selector ".quiz-hud-rank .quiz-hud-level"
    assert_selector ".quiz-hud-score [data-quiz-target=score]", text: "5"
    assert_selector ".quiz-hud-streak img.quiz-hud-streak-icon[src*='living-fire-hud-v1.webp']", count: 1
    assert_selector ".quiz-hud-streak-multiplier", text: "×"
    assert_selector ".quiz-hud-streak.is-grew.is-shout[data-tier=glow] .quiz-hud-streak-num", text: "2"
    assert_selector "a.quiz-hud-who[href='/']"
  end

  test "quiz HUD keeps a rankless player level attached to their name" do
    bar = Huds::Present::Result.new(
      kind: :quiz,
      guest: false,
      name: "Tracy",
      level: 1,
      pack_title: "L'Éternel",
      progress_n: 5,
      progress_total: 10,
      dots: ([ "is-done" ] * 5) + ([ "is-next" ] * 5),
      score: 31,
      combo: Huds::Present::Combo.new(count: 5, tier: "hot", broke: false, grew: false, shout_key: nil)
    )
    render_inline(Hud::BarComponent.new(bar:))

    assert_selector ".quiz-hud-name .quiz-hud-level", text: "1"
    assert_no_selector ".quiz-hud > .quiz-hud-level"
  end

  test "finished quiz keeps the level disc with the player identity, not in the pack" do
    bar = Huds::Present::Result.new(
      kind: :quiz,
      guest: false,
      name: "Loona",
      rank_key: "explorador",
      level: 2,
      pack_title: "Rois",
      progress_n: 10,
      progress_total: 10,
      dots: Array.new(10, "is-done"),
      score: 40,
      done: true,
      combo: Huds::Present::Combo.new(count: 1, tier: "spark", broke: false, grew: false, shout_key: nil)
    )
    render_inline(Hud::BarComponent.new(bar:))

    assert_selector ".quiz-hud-name .quiz-hud-level", text: "2"
    assert_no_selector ".quiz-hud-rank .quiz-hud-level"
    assert_no_selector ".quiz-hud > .quiz-hud-level"
    assert_no_selector ".quiz-hud-pack .quiz-hud-level"
  end

  test "late Hub and quiz styles preserve glass accessibility fallbacks" do
    hub_css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
    quiz_css = Rails.root.join("app/assets/stylesheets/surfaces/street_play.css").read

    assert_equal 3, hub_css.scan("body.is-game-hub-page .home-menu.is-hud.is-compact .quiz-hud:not(.is-quiz)").size
    guard_start = quiz_css.rindex("/* The quiz owns its artwork theme")
    last_quiz_blur = quiz_css.rindex("backdrop-filter: blur(14px);")
    assert guard_start
    assert last_quiz_blur
    assert_operator guard_start, :>, last_quiz_blur

    [ hub_css, quiz_css ].each do |css|
      assert_includes css, "@supports not ((-webkit-backdrop-filter: blur(1px)) or (backdrop-filter: blur(1px)))"
      assert_includes css, "@media (prefers-reduced-transparency: reduce)"
      assert_includes css, "@media (forced-colors: active)"
      assert_includes css, "background: Canvas;"
      assert_includes css, "backdrop-filter: none;"
    end
  end
end
