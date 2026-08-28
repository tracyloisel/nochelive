require "application_system_test_case"

class StreetQuizVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots")
  TEMPLE_SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "liga lives in the celestial court with full viewport chrome" do
    set_quiz_viewport(390, 844)
    seed_liga_visual_rows!
    sign_in_fixture_person_direct!(people(:pili))
    visit street_leaderboard_path

    assert_no_horizontal_layout_overflow

    assert_selector ".street-leaderboard-page[data-controller~='liga-board']"
    assert_selector ".street-liga-scope"
    assert_selector ".street-liga-podium"
    assert_selector ".street-liga-you-bar", visible: :all
    assert_no_selector "select"
    assert_layout_chrome_full_width
    page.execute_script("document.querySelector('#street_world')?.classList.remove('is-liga-enter')")
    shot("liga-phone")
    set_quiz_viewport(804, 1436)
    page.execute_script("window.scrollTo(0, 0)")
    shot("liga-tablet")
  end

  test "layout chrome keeps one viewport contract across destinations" do
    set_quiz_viewport(804, 1_100)
    sign_in_fixture_person_direct!(people(:pili))

    [
      [ root_path, nil, "hub" ],
      [ street_map_path, "celestial-light", "adventure" ],
      [ street_leaderboard_path, "celestial-light", "league" ],
      [ study_program_path, "celestial-light", "word" ],
      [ church_path, "celestial-dark", "church" ],
      [ ward_profile_path(wards(:demo).code), "celestial-dark", "ward" ]
    ].each do |path, expected_theme, shot_name|
      visit path
      assert_selector "body > .home-menu.is-hud"
      assert_selector "body > .navigation-dock"
      assert_layout_chrome_full_width
      assert_hud_theme_contract(expected_theme)
      shot("hud-route-#{shot_name}")
    end
  end

  test "hub HUD renders the same anatomy in celestial light and dark" do
    set_quiz_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
    worlds = {
      "celestial-light" => catalog.find { |row| row["id"] == "eden-lumiere" },
      "celestial-dark" => catalog.find { |row| row["id"] == "coronas-ungido" }
    }

    worlds.each do |theme, row|
      Hubs::Backdrop.entries = [ row ]
      visit root_path
      assert_selector "body.is-#{theme}"
      assert_hud_theme_contract(theme)
      assert_selector ".quiz-hud-who"
      assert_selector ".quiz-hud-pack"
      assert_selector ".quiz-hud-stats"
      assert_selector ".quiz-hud-menu"
      shot("hud-#{theme}")
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "defis opens on the stake rivalry and offers live async matches" do
    set_quiz_viewport(390, 844)
    StreetDuel.active.destroy_all
    load Rails.root.join("db/seeds.rb")
    sign_in_fixture_person_direct!(people(:pili))
    visit street_challenges_path
    page.execute_script("window.scrollTo(0, 0)")

    assert_no_horizontal_layout_overflow
    title_gap = page.evaluate_script(<<~JS)
      document.querySelector('.street-duel-title').getBoundingClientRect().top -
        document.querySelector('.home-menu.is-hud').getBoundingClientRect().bottom
    JS
    assert_operator title_gap, :>=, 16

    assert_selector ".street-stake-rivalry"
    assert_selector ".street-duel-live-card"
    assert_selector ".street-duel-rival-button"
    assert_selector ".street-duel-history"
    shot("duels-phone")
    set_quiz_viewport(804, 1436)
    page.scroll_to(:top)
    assert_no_horizontal_layout_overflow
    assert_operator page.evaluate_script("getComputedStyle(document.querySelector('.street-duel-pick ul')).gridTemplateColumns.split(' ').length"), :>=, 2
    shot("duels-tablet")
    set_quiz_viewport(1024, 768)
    page.scroll_to(:top)
    assert_no_horizontal_layout_overflow
    assert_operator page.evaluate_script("getComputedStyle(document.querySelector('.street-duel-board')).gridTemplateColumns.split(' ').length"), :>=, 2
    shot("duels-ipad-landscape")
    set_quiz_viewport(1440, 900)
    page.scroll_to(:top)
    assert_no_horizontal_layout_overflow
    assert_operator page.evaluate_script("document.querySelector('.street-duel-inbox').getBoundingClientRect().width"), :>, 1100
    shot("duels-desktop")
    set_quiz_viewport(390, 844)
  end

  test "jugar ask has no chase chip on the still" do
    page.current_window.resize_to(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    assert_no_selector "#profile_gate"
    assert_selector ".street-map-door-play", wait: 5
    find(".street-map-door-play").click
    assert_selector "#street_quiz.play-reel.is-quiz.is-street.is-overlay"
    assert_no_selector ".street-shot-rival"
    assert_selector ".quiz-hud-avatar"
    assert_selector ".home-menu.is-split .home-menu-btn"
    assert_no_selector ".chrome-tools"
    assert_jugar_chrome_on_column
    sleep 0.5
    shot("01-ask-phone")
  end

  test "jugar hub row returns to the hub" do
    page.current_window.resize_to(390, 844)
    ready_street_quiz!
    find(".home-menu-btn").click
    click_link I18n.t("street.nav_hub")
    assert_selector "#street_world"
    assert_no_selector "#street_quiz"
  end

  test "hub pulse reloads live count without leaving the hub" do
    page.current_window.resize_to(390, 844)
    PersonDevice.update_all(last_seen_at: 1.hour.ago)
    Player.update_all(last_seen_at: 1.hour.ago)
    visit root_path
    assert_selector ".street-pulse[data-pulse-online='0']"
    assert_selector "#street_world"
    person_devices(:pili_tablet).update_column(:last_seen_at, Time.current)
    page.execute_script("document.querySelector('turbo-frame#street_pulse').reload()")
    assert_selector ".street-pulse[data-pulse-online='1']", wait: 5
    assert_selector "#street_world"
    assert_no_selector "#street_quiz"
  end

  test "hub league strip with signed-in profile" do
    set_quiz_viewport(390, 844)
    person = people(:pili)
    sign_in_fixture_person_direct!(person)
    token = PersonDevice.where(person:).order(:id).last&.device_token
    digest = GameSession.digest_token(token) if token.present?
    if digest
      QuizRun.create!(
        device_digest: digest,
        person:,
        pack_id: QuizDefinition.catalog.pack_ids.first,
        position: 10,
        score: 80,
        status: "finished",
        opened_at: Time.current
      )
    end
    QuizRun.create!(
      device_digest: "hub-league-lopez",
      person: people(:carmen_lopez),
      pack_id: QuizDefinition.catalog.pack_ids.first,
      position: 10,
      score: 70,
      status: "finished",
      opened_at: Time.current
    )
    visit root_path
    assert_no_selector "#profile_gate"
    assert_selector ".quiz-hud"
    assert_no_selector ".hub-mini"
    assert_selector ".hub-rail.is-empty"
    assert_selector ".quiz-hud-name", text: person.given_name
    assert_selector ".quiz-hud-rank"
    assert_no_selector ".street-xp-bar"
    assert_selector ".street-card.is-map-door"
    assert_selector ".street-map-door-kicker"
    assert_selector ".hub-hero-stage"
    assert_selector ".hub-hero-continue"
    assert_selector ".hub-reward-label"
    assert_selector ".hub-reward img.hub-reward-chest"
    assert_selector ".street-map-door-play", text: /#{Regexp.escape(I18n.t("street.world_play"))}/i
    assert_selector ".street-pulse"
    assert_no_selector ".navigation-dock .street-play-cta"
    assert_no_selector ".street-map-door-open"
    assert_selector ".street-map-door-step"
    assert_no_selector "#street_world .street-map-path"
    assert_selector ".street-rank-banner", count: 0
    assert_selector ".quiz-hud-rank"
    assert_no_selector ".street-pack-play"
    page.execute_script("window.scrollTo(0, 0)")
    sleep 0.6
    find(".home-menu-btn").click
    assert_selector "dialog.chrome-drawer[open] .home-menu-nav"
    assert_selector ".quiz-hud-avatar"
    assert_selector ".home-menu-row", text: I18n.t("street.history_menu")
    assert_selector ".home-menu-row", text: I18n.t("street.world_map")
    assert_no_selector ".home-menu-row", text: I18n.t("street.nav_hub")
    shot("hub-menu-phone")
    find(".home-menu-btn").click
    assert_no_selector "dialog.chrome-drawer[open]"
    assert_hub_shell_pinned
    assert_above_hub_dock ".hub-hero"
    assert_above_hub_dock ".street-card.is-map-door"
    assert_no_selector ".chrome-tools"
    assert_selector ".navigation-dock a.navigation-dock__item", count: 5
    assert_selector ".navigation-dock a[href='/']"
    assert_selector ".navigation-dock a[href='/mapa']"
    assert_selector ".navigation-dock a[href='/parole']"
    assert_selector ".navigation-dock a[href='/iglesia']"
    assert_selector ".navigation-dock__item[href='/parole'] > .picto-scripture-book"
    assert_no_selector ".street-hub-word-medallion"
    assert_no_selector ".navigation-dock .picto-bell"
    assert_no_selector ".hub-shortcuts"
    assert_layout_chrome_full_width
    assert_no_horizontal_layout_overflow
    shot("hub-league-phone")
    shot("hub-phone")
    open_hub_map_from_menu
    assert_selector ".street-map-page"
    assert_selector ".mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_selector ".mapa-node.is-current"
    assert_selector ".mapa-node.is-locked"
    assert_no_selector ".mapa-node.is-locked .mapa-node-hit"
    shot("map-phone")
    find(".navigation-dock a[href='/']").click
    assert_selector ".street-card.is-map-door"
    assert_no_selector "#street_world .street-map-path"
    assert_abuelo_type_floor
    [
      [ 768, 1024, "hub-ipad" ],
      [ 1024, 768, "hub-ipad-land" ],
      [ 1280, 800, "hub-desktop" ],
      [ 1920, 1080, "hub-xl" ]
    ].each do |width, height, name|
      set_quiz_viewport(width, height)
      sleep 0.35
      assert_layout_chrome_full_width
      assert_abuelo_type_floor
      shot(name)
    end
    set_quiz_viewport(390, 844)
  end

  test "desafio sits on the marble hall" do
    page.current_window.resize_to(390, 844)
    sign_in_street_rival!
    visit street_challenge_path(street_duels(:pending_challenge).token)

    assert_no_horizontal_layout_overflow
    assert_selector "body.is-paper-hall"
    assert_selector "#street_desafio .hall-sheet"
    assert_selector "h1", text: I18n.t("street.duel_title")
    assert_selector ".btn-gold", text: I18n.t("street.duel_accept")
    assert_no_selector ".gate"
    sleep 0.4
    shot("desafio-phone")
    page.current_window.resize_to(390, 844)
  end

  test "liga name search filters as you type" do
    page.current_window.resize_to(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    ward = wards(:demo)
    ana = ward.people.create!(given_name: "Anabel", avatar_key: "gato", favorite_year: 2021)
    QuizRun.create!(
      device_digest: "liga-type-ana",
      person: ana,
      pack_id: "coronas",
      position: 10,
      score: 42,
      status: "finished",
      opened_at: Time.current
    )
    visit street_leaderboard_path
    assert_selector "[data-controller~='liga-search']"
    assert_selector ".street-liga-entry", text: /Carmen/
    find("#leaderboard_q").set("Ana")
    assert_no_selector ".street-liga-entry", text: /Carmen/, wait: 6
    assert_selector ".street-liga-entry", text: /Anabel/
    assert_no_selector ".street-liga-podium"
    assert_includes page.current_url, "q=Ana"
    assert_equal "leaderboard_q", page.evaluate_script("document.activeElement && document.activeElement.id")
    find("#leaderboard_q").send_keys(:escape)
    assert_selector ".street-liga-entry", text: /Carmen/, wait: 6
    assert_selector ".street-liga-podium"
    assert_no_match(/[?&]q=/, page.current_url)
  end

  test "hub rank up ring on player card" do
    page.current_window.resize_to(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    visit root_path(rank_up: 1)
    assert_selector ".quiz-hud.is-rank-up"
    sleep 0.6
    shot("rank-up-phone")
  end

  test "hub pack unlock animation" do
    page.current_window.resize_to(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    next_pack = QuizDefinition.catalog.pack_ids.second
    visit street_map_path(unlock: next_pack)
    assert_selector "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    sleep 0.5
    shot("hub-pack-unlock-phone")
  end

  test "pack ceremony on last question" do
    set_quiz_viewport(390, 844)
    QuizRun.where(status: "open").update_all(status: "finished")
    sign_in_fixture_person_direct!(people(:pili))
    find(".street-map-door-play").click
    assert_selector "#street_quiz"
    run = QuizRun.open_runs.order(:id).last
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    seed_ceremony_board!(run.pack_id)
    question = pack.question_at(10)
    pack.questions.first(9).each do |answered|
      run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: answered.id,
        choice_key: answered.correct_choice,
        correct: true
      )
    end
    run.update!(position: 10, score: pack.questions.first(9).sum(&:points), ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: question.correct_choice)
    visit jugar_path
    assert_selector ".quiz-board.is-settled"
    click_button I18n.t("quiz.next")
    assert_selector "#street_quiz.is-overlay.is-ceremony"
    assert_selector "#street_quiz[data-street-motion-sequence-value='packComplete']"
    assert_selector ".street-ceremony-fire.is-earned", count: 4
    assert_selector ".score-fly[data-from='103'][data-final='124'][data-fire-bonus='21']"
    assert_selector ".street-ceremony-score-math", text: /103\s*\+21/
    assert_ceremony_temple_scrim
    sleep 2.5
    wait_for_brush_fonts!
    assert_ceremony_breakpoints!
  end

  test "challenge button on pack ceremony" do
    set_quiz_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    QuizRun.where(status: "open").update_all(status: "finished")
    visit root_path
    find(".street-map-door-play").click
    assert_selector "#street_quiz"
    run = QuizRun.open_runs.order(:id).last
    assert run, "expected open quiz run after starting pack"
    seed_ceremony_board!(run.pack_id)
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    question = pack.question_at(10)
    run.update!(position: 10, score: 80, ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: question.correct_choice)
    visit jugar_path
    assert_selector ".quiz-board.is-settled"
    click_button I18n.t("quiz.next")
    assert_selector "#street_quiz.is-overlay.is-ceremony"
    assert_selector ".street-ceremony-boards"
    assert_selector ".street-challenge-btn"
    assert_no_selector ".street-card.is-share"
    sleep 2.5
    wait_for_brush_fonts!
    assert_in_viewport ".street-challenge-btn", slop: 48
    shot("ceremony-challenge-phone")
  end

  test "street quiz sheet type miss ticks and swipe" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    assert_selector "#street_quiz[data-controller~=story]"
    assert_selector "#street_quiz.is-overlay"
    assert_no_selector ".story-ticks"
    assert_no_selector ".story-close"
    assert_selector ".quiz-sheet"
    assert_no_selector "a.street-quiz-lockup"
    assert_selector ".street-quiz-apex"
    assert_apex_above_sheet!
    assert_selector ".quiz-kicker"
    assert_no_selector "#street_quiz .choice-mark"
    assert_selector ".street-score span", text: "0"
    assert_no_selector "#street_quiz .btn.btn-gold"
    assert_operator score_top, :>, 0
    assert_operator score_top, :<, 0.35
    peek = sheet_top
    assert_operator peek, :>=, 0.42
    visible = visible_choice_count
    assert_operator visible, :>=, 2
    pair("01-ask")

    wrong = page.all(".choice-btn").find { |btn| btn["data-choice-key"] != find("#street_quiz")["data-quiz-correct-value"] }
    wrong.click
    assert_selector ".quiz-board.is-wrong"
    assert_apex_above_sheet!
    assert_selector ".quiz-bar.is-correct.is-right"
    assert_selector ".quiz-bar.is-wrong.is-miss"
    assert_selector ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick"
    assert_selector ".quiz-bar.is-wrong.is-miss .quiz-flag.is-no .picto-cross"
    assert_selector "a.quiz-scripture .quiz-read", text: I18n.t("quiz.read")
    assert_selector "a.quiz-scripture .quiz-cite", text: QuizRun.order(:id).last.question.scripture.cite
    assert_no_text I18n.t("quiz.read_more")
    assert_selector ".quiz-sheet"
    assert_selector ".street-score span", text: "0"
    assert_no_selector ".street-score.is-tick"
    assert_selector ".street-praise.is-miss", text: I18n.t("quiz.almost")
    assert_no_selector ".quiz-shout"
    pair("02-miss")
    assert_settled_choice_row! page.first(".quiz-bar")
    assert_settled_choice_row! page.first(".quiz-bar.is-correct")

    click_button I18n.t("quiz.next")
    assert_selector ".choice-btn"
    assert_selector ".quiz-sheet"
    assert_selector ".street-score span", text: "0"
    assert_no_selector "#street_quiz .btn.btn-gold"
    pair("02b-next-ask")
    right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
    right.click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".quiz-sheet"
    assert_selector ".street-score"
    assert_selector ".street-praise"
    run = QuizRun.order(:id).last
    shout = ApplicationController.helpers.street_praise_line(run, run.question)
    assert_selector ".street-praise-line", text: shout
    assert_praise_inside_shot(shout)
    pair("03-right")

    swipe("#street_quiz .play-shot", dx: 160, dy: 0)
    assert_selector ".quiz-progress", text: /1 \/ 10/
    assert_selector ".quiz-board.is-settled"
    pair("04-swipe-back")

    swipe("#street_quiz .play-shot", dx: -160, dy: 0)
    assert_selector ".quiz-progress", text: /2 \/ 10/
    pair("05-swipe-next")

    click_button I18n.t("quiz.next")
    assert_selector ".choice-btn"
    first(".choice-btn").click
    click_button I18n.t("quiz.next")
    assert_selector "#street_quiz[data-stage-timer-end-value]"
    assert_selector "#street_quiz[data-stage-timer-duration-value]"
    duration = find("#street_quiz")["data-stage-timer-duration-value"].to_i
    assert_operator duration, :>, 0
    assert_no_selector ".play-timer.is-warn"
    assert_no_selector ".play-timer.is-low"
    assert_no_selector "#street_quiz.is-timer-warn"
    assert_no_selector "#street_quiz.is-timer-hot"
    pair("06-timed")
  end

  test "settled four bars keep next on the still" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    run = QuizRun.order(:id).last
    question = QuizDefinition.catalog.find_pack("coronas").question_at(2)
    run.update!(pack_id: "coronas", position: 2, score: 0, ends_at: nil, status: "open")
    visit jugar_path

    wrong = page.all(".choice-btn").find { |btn| btn["data-choice-key"] != question.correct_choice }
    wrong.click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".quiz-bar", count: 4
    assert_selector ".quiz-bar .quiz-flag", count: 4
    assert_selector ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_selector ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross", count: 3
    assert_settled_choice_row! page.first(".quiz-bar")
    assert_settled_choice_row! page.first(".quiz-bar.is-correct")
    assert_selector ".play-shot .street-shot-actions .quiz-next"
    assert_selector ".play-shot a.quiz-scripture"
    assert_in_viewport ".play-shot .street-shot-actions .quiz-next"
    assert_no_selector ".street-quiz-dock"
    assert_no_selector ".quiz-board .quiz-next"
    assert_no_selector ".quiz-board .quiz-scripture"
    shot("07-four-bars-settled")
  end

  def seed_ceremony_board!(pack_id)
    ward = wards(:demo)
    [
      [ people(:pili), 102 ],
      [ people(:carmen_garcia), 95 ],
      [ people(:carmen_lopez), 87 ]
    ].each do |person, score|
      run = QuizRun.find_or_initialize_by(person_id: person.id, pack_id:)
      next if run.persisted? && run.open?

      run.device_digest ||= GameSession.digest_token("ceremony-board-#{person.id}")
      run.position = 10
      run.score = score
      run.status = "finished"
      run.opened_at ||= Time.current
      run.save!
    end
    lucia = Person.find_or_initialize_by(ward:, given_name_key: "lucia", family_name_key: "soto")
    lucia.assign_attributes(
      given_name: "Lucía",
      family_name: "Soto",
      avatar_key: "loro",
      favorite_year: 2009
    )
    lucia.save!
    return if QuizRun.exists?(person_id: lucia.id, pack_id:)

    QuizRun.create!(
      person: lucia,
      pack_id:,
      device_digest: GameSession.digest_token("ceremony-board-lucia"),
      position: 10,
      score: 76,
      status: "finished",
      opened_at: Time.current
    )
  end

  test "street praise stays inside the still" do
    page.current_window.resize_to(390, 844)
    ready_street_quiz!
    right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
    right.click
    assert_selector ".street-praise-line"
    assert_praise_inside_shot
    %w[Spectaculaire ! Excellentissime ! Spectacular! ¡Espectacular!].each do |line|
      assert_praise_inside_shot(line)
    end
    page.current_window.resize_to(768, 1024)
    assert_praise_inside_shot("Spectaculaire !")
    page.current_window.resize_to(1280, 800)
    assert_praise_inside_shot("Spectaculaire !")
  end

  def ready_street_quiz!
    sign_in_fixture_person_direct!(people(:pili))
    find(".street-map-door-play").click if page.has_css?(".street-map-door-play", wait: 1)
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
  end

  def clear_street_session!
    page.driver.browser.manage.delete_all_cookies
  end

  def sign_in_fixture_person_direct!(person)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.post enter_ward_path, params: { code: person.ward.code }
    session.post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }

    clear_street_session!
    visit root_path
    session.cookies.to_hash.each do |name, value|
      page.driver.browser.manage.add_cookie(name:, value:, path: "/")
    end
    visit root_path
  end

  def seed_liga_visual_rows!
    ward = wards(:demo)
    %w[Miguel Sophie Ingrid Lucas Elise].zip([ 74, 61, 48, 36, 24 ], Player::AVATARS.cycle).each_with_index do |(name, score, avatar), index|
      person = ward.people.create!(given_name: name, avatar_key: avatar, favorite_year: 2000 + index)
      QuizRun.create!(device_digest: "liga-visual-#{index}", person:, pack_id: "coronas", position: 10, score:, status: "finished", opened_at: Time.current)
    end
  end

  def sign_in_street_rival!(name: "Carmen")
    sign_in_fixture_person_direct!(people(:carmen_garcia))
  end

  def assert_in_viewport(selector, slop: 8)
    visible = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        return r.top >= -8 && r.bottom <= (window.innerHeight + #{slop.to_i}) && r.height > 0;
      })()
    JS
    assert visible, "#{selector} should sit in the first screen"
  end

  def assert_ceremony_title_clears_hud
    gap = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector("#street_quiz.is-ceremony .quiz-hud");
        var shout = document.querySelector(".street-ceremony-shout");
        if (!hud || !shout) return null;
        return shout.getBoundingClientRect().top - hud.getBoundingClientRect().bottom;
      })()
    JS
    assert gap, "ceremony shout should be measurable against the HUD"
    assert_operator gap.to_f, :>=, 32, "ceremony title should breathe under the HUD (got #{gap}px)"
  end

  def assert_ceremony_stack_on_column
    measured = page.evaluate_script(<<~JS)
      (function() {
        var quiz = document.querySelector("#street_quiz.is-ceremony");
        var hud = document.querySelector("#street_quiz.is-ceremony .quiz-hud");
        var stack = document.querySelector("#street_quiz.is-ceremony .street-ceremony");
        if (!quiz || !hud || !stack) return null;
        var root = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
        var raw = getComputedStyle(document.documentElement).getPropertyValue("--street-play-col").trim();
        var q = quiz.getBoundingClientRect();
        var colPx = raw.endsWith("rem") ? parseFloat(raw) * root : q.width;
        var h = hud.getBoundingClientRect();
        var s = stack.getBoundingClientRect();
        var mid = (q.left + q.right) / 2;
        return {
          hudW: Math.round(h.width),
          stackW: Math.round(s.width),
          colPx: Math.round(Math.min(colPx, q.width - 24)),
          hudCentered: Math.abs((h.left + h.right) / 2 - mid) < 20,
          stackCentered: Math.abs((s.left + s.right) / 2 - mid) < 20,
          hudFits: h.width <= Math.min(colPx, q.width) + 24
        };
      })()
    JS
    assert measured, "ceremony HUD and stack should be measurable"
    assert measured["hudFits"], "ceremony HUD should pin to the play column (hud=#{measured["hudW"]} col=#{measured["colPx"]})"
    assert_in_delta measured["hudW"], measured["stackW"], 20
    assert measured["hudCentered"], "ceremony HUD should stay centered on the still"
    assert measured["stackCentered"], "ceremony stack should stay centered on the still"
  end

  def assert_ceremony_scroll_top!
    page.execute_script(<<~JS)
      var sc = document.querySelector("#street_quiz.is-ceremony .street-ceremony-scroll");
      if (sc) sc.scrollTop = 0;
    JS
  end

  def assert_ceremony_breakpoints!
    assert_ceremony_scroll_top!
    assert_ceremony_title_clears_hud
    assert_ceremony_stack_on_column
    assert_jugar_chrome_on_column
    assert_in_viewport ".street-challenge-btn, .street-duel-waiting-note", slop: 48
    assert_in_viewport ".street-ceremony-share", slop: 72
    shot("ceremony-phone")
    [
      [ 768, 1024, "jugar-ceremony-ipad" ],
      [ 1280, 800, "jugar-ceremony-desktop" ],
      [ 1920, 1080, "jugar-ceremony-xl" ]
    ].each do |width, height, name|
      set_quiz_viewport(width, height)
      assert_ceremony_scroll_top!
      sleep 0.35
      assert_ceremony_title_clears_hud
      assert_ceremony_stack_on_column
      assert_jugar_chrome_on_column
      shot(name)
    end
    set_quiz_viewport(390, 844)
  end

  def open_hub_map_from_menu
    find(".home-menu-btn").click
    assert_selector "dialog.chrome-drawer[open] .home-menu-nav"
    click_link I18n.t("street.world_map")
  end

  def assert_no_horizontal_layout_overflow
    overflow = page.evaluate_script(<<~JS)
      (function() {
        var viewport = document.documentElement.clientWidth;
        var offenders = Array.from(document.querySelectorAll("body *")).filter(function(el) {
          if (el.matches(".skip, .ripple, [aria-hidden='true']")) return false;
          var style = getComputedStyle(el);
          if (style.position === "fixed" || style.visibility === "hidden" || style.display === "none") return false;
          var scrollParent = el.parentElement;
          while (scrollParent && scrollParent !== document.body) {
            var overflowX = getComputedStyle(scrollParent).overflowX;
            if (overflowX === "auto" || overflowX === "scroll") return false;
            scrollParent = scrollParent.parentElement;
          }
          var rect = el.getBoundingClientRect();
          return rect.width > 0 && (rect.left < -2 || rect.right > viewport + 2);
        });
        return offenders.slice(0, 8).map(function(el) {
          var rect = el.getBoundingClientRect();
          return (el.id ? "#" + el.id : el.className || el.tagName) + " [" + rect.left.toFixed(1) + ", " + rect.right.toFixed(1) + "]";
        });
      })()
    JS
    assert_empty overflow, "layout content must fit the viewport: #{overflow.join(', ')}"
  end

  def assert_hub_shell_pinned
    pinned = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector(".home-menu.is-hud .quiz-hud") || document.querySelector("#street_world .quiz-hud");
        var burger = document.querySelector(".home-menu > .home-menu-btn");
        var dock = document.querySelector(".navigation-dock");
        var feed = document.querySelector(".street-hub-feed");
        if (!hud || !burger || !dock || !feed) return false;
        if (document.querySelector(".hub-mini")) return false;
        var overflow = getComputedStyle(feed).overflowY;
        var menu = hud.closest(".home-menu");
        var menuPos = menu ? getComputedStyle(menu).position : getComputedStyle(hud).position;
        var before = hud.getBoundingClientRect();
        var burgerBox = burger.getBoundingClientRect();
        var burgerInHud = burgerBox.left >= before.left - 6
          && burgerBox.right <= before.right + 6
          && burgerBox.top >= before.top - 6
          && burgerBox.bottom <= before.bottom + 6;
        var hero = document.querySelector(".hub-hero") || document.querySelector(".street-hub-feed .street-card.is-map-door");
        var heroBefore = hero ? hero.getBoundingClientRect().top : before.bottom + 8;
        var dockBefore = dock.getBoundingClientRect().top;
        feed.scrollTop = Math.min(feed.scrollHeight, 280);
        feed.dispatchEvent(new Event("scroll"));
        var after = hud.getBoundingClientRect();
        var dockAfter = dock.getBoundingClientRect().top;
        feed.scrollTop = 0;
        feed.dispatchEvent(new Event("scroll"));
        return (overflow === "auto" || overflow === "scroll")
          && menuPos === "fixed"
          && burgerInHud
          && before.height >= 44 && before.height <= 104
          && heroBefore >= before.bottom - 12
          && Math.abs(after.top - before.top) < 10
          && Math.abs(dockBefore - dockAfter) < 2;
      })()
    JS
    assert pinned, "quiz HUD capsule should stay compact with the hamburger in the slot while the hub feed scrolls"
  end

  def assert_hub_league_on_cta
    assert_above_hub_dock ".street-league"
  end

  def assert_above_hub_dock(selector)
    visible = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        var cta = document.querySelector(".navigation-dock") || document.querySelector(".street-pulse") || document.querySelector(".street-play-cta");
        var limit = cta ? cta.getBoundingClientRect().top : window.innerHeight;
        return r.top >= -8 && r.bottom <= (limit + 8) && r.height > 0;
      })()
    JS
    assert visible, "#{selector} should sit above JUGAR on the first fold"
  end

  def assert_layout_chrome_full_width
    measured = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector("body > .home-menu.is-hud");
        var dock = document.querySelector("body > .navigation-dock");
        if (!hud || !dock) return null;
        var h = hud.getBoundingClientRect();
        var d = dock.getBoundingClientRect();
        var viewport = document.documentElement.clientWidth;
        return {
          viewport: viewport,
          hudW: h.width,
          dockW: d.width,
          hudLeft: h.left,
          dockLeft: d.left,
          hudPosition: getComputedStyle(hud).position,
          dockPosition: getComputedStyle(dock).position
        };
      })()
    JS
    assert measured, "the layout HUD and dock should both be present"
    assert_equal "fixed", measured["hudPosition"]
    assert_equal "fixed", measured["dockPosition"]
    assert_in_delta measured["viewport"], measured["hudW"], 2, "HUD should span the viewport"
    assert_in_delta measured["viewport"], measured["dockW"], 2, "dock should span the viewport"
    assert_in_delta 0, measured["hudLeft"], 2, "HUD should start at the viewport edge"
    assert_in_delta 0, measured["dockLeft"], 2, "dock should start at the viewport edge"
  end

  def assert_hud_theme_contract(expected_theme = nil)
    measured = page.evaluate_script(<<~JS)
      (function() {
        var menu = document.querySelector("body > .home-menu.is-hud");
        var hud = menu && menu.querySelector(".quiz-hud");
        if (!menu || !hud) return null;

        var parseColor = function(value) {
          var probe = document.createElement("span");
          probe.style.color = value;
          document.body.appendChild(probe);
          var resolved = getComputedStyle(probe).color;
          probe.remove();
          var parts = resolved.match(/[\\d.]+/g).map(Number);
          return { r: parts[0], g: parts[1], b: parts[2], a: parts[3] == null ? 1 : parts[3] };
        };
        var blend = function(color, under) {
          return {
            r: color.r * color.a + under * (1 - color.a),
            g: color.g * color.a + under * (1 - color.a),
            b: color.b * color.a + under * (1 - color.a)
          };
        };
        var luminance = function(color) {
          var channel = function(value) {
            value = value / 255;
            return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
          };
          return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
        };
        var contrast = function(a, b) {
          var la = luminance(a);
          var lb = luminance(b);
          return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
        };
        var style = getComputedStyle(hud);
        var text = parseColor(style.color);
        var glass = parseColor(style.getPropertyValue("--quiz-glass").trim());

        return {
          menuTheme: menu.dataset.hudTheme,
          hudTheme: hud.dataset.hudTheme,
          onBlack: contrast(text, blend(glass, 0)),
          onWhite: contrast(text, blend(glass, 255))
        };
      })()
    JS

    assert measured, "the shared HUD must expose its theme and contrast tokens"
    mode = find("body", visible: :all)[:class][/\bis-celestial-(light|dark)\b/, 1]
    expected_theme ||= "celestial-#{mode}" if mode
    assert_includes Hud::BarComponent::THEMES, expected_theme
    assert_equal expected_theme, measured["menuTheme"]
    assert_equal expected_theme, measured["hudTheme"]
    assert_operator measured["onBlack"], :>=, 7.0, "#{expected_theme} HUD must remain AAA on a black artwork region"
    assert_operator measured["onWhite"], :>=, 7.0, "#{expected_theme} HUD must remain AAA on a white artwork region"
  end

  def assert_praise_inside_shot(shout = nil)
    if shout.present?
      page.execute_script(<<~JS, shout)
        var line = document.querySelector(".street-praise-line");
        if (line) line.textContent = arguments[0];
      JS
    end
    fit = page.evaluate_script(<<~JS)
      (function() {
        var shot = document.querySelector("#street_quiz .play-shot");
        var line = document.querySelector(".street-praise-line");
        if (!shot || !line) return null;
        var s = shot.getBoundingClientRect();
        var l = line.getBoundingClientRect();
        return {
          text: line.textContent,
          leftOk: l.left >= s.left - 1,
          rightOk: l.right <= s.right + 1,
          topOk: l.top >= s.top - 1,
          bottomOk: l.bottom <= s.bottom + 1,
          lineW: Math.round(l.width),
          shotW: Math.round(s.width)
        };
      })()
    JS
    assert fit, "praise line should be on the still"
    assert fit["leftOk"] && fit["rightOk"],
      "praise #{fit["text"].inspect} should stay in the still (line #{fit["lineW"]}px, shot #{fit["shotW"]}px)"
    assert fit["topOk"] && fit["bottomOk"],
      "praise #{fit["text"].inspect} should stay vertically in the still"
  end

  def assert_jugar_chrome_on_column
    aligned = page.evaluate_script(<<~JS)
      (function() {
        var quiz = document.querySelector("#street_quiz");
        var face = document.querySelector(".quiz-hud-avatar") || document.querySelector(".chrome-face");
        var burger = document.querySelector(".home-menu > .home-menu-btn");
        var mute = document.querySelector(".chrome-tools .mute");
        var flag = document.querySelector(".chrome-tools .lang-switch");
        if (!quiz || !face || !burger) return false;
        if (mute || flag) return false;
        var q = quiz.getBoundingClientRect();
        var f = face.getBoundingClientRect();
        var b = burger.getBoundingClientRect();
        var mid = (q.left + q.right) / 2;
        return f.left >= q.left - 12 && b.right <= q.right + 12 && b.left > mid && f.right < mid && f.height > 0 && b.height > 0;
      })()
    JS
    assert aligned, "jugar keeps avatar left and hamburger right on the phone arch; mute and flag stay in the drawer"
  end

  def assert_abuelo_type_floor
    sizes = page.evaluate_script(<<~JS)
      (function() {
        var root = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
        var minPx = parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--type-min")) * root;
        var read = function(sel) {
          var el = document.querySelector(sel);
          return el ? parseFloat(getComputedStyle(el).fontSize) : null;
        };
        return {
          minPx: minPx,
          pack: read(".street-map-door-pack"),
          banner: read(".quiz-hud-rank"),
          name: read(".quiz-hud-name")
        };
      })()
    JS
    assert sizes, "type floor metrics should be readable"
    floor = sizes["minPx"] - 0.6
    %w[pack banner name].each do |key|
      next unless sizes[key]
      assert sizes[key] >= floor, "#{key} font-size #{sizes[key]} should be ≥ type-min #{sizes["minPx"]}"
    end
  end

  def assert_ceremony_temple_scrim
    assert_selector "#street_quiz.is-overlay.is-ceremony"
    assert_selector ".quiz-hud"
    assert_selector ".street-ceremony-shout"
    assert_selector ".street-ceremony-medallion"
    assert_selector ".street-ceremony-stats"
    assert_ceremony_title_clears_hud
    assert_selector ".street-ceremony-boards"
    assert_selector ".street-ceremony-laurel"
    assert_selector ".street-ceremony-score-label"
    assert_selector ".street-ceremony-chest-img"
    assert_selector ".street-ceremony-map"
    assert_selector ".street-challenge-btn"
    assert_selector ".street-ceremony-share"
    assert_selector ".street-ceremony-best-row", minimum: 1
    assert_no_selector ".street-ceremony-lockup"
    assert_no_selector ".street-ceremony-plinth"
    hall = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector("#street_quiz .challenge-story");
        if (!el) return "";
        return el.getAttribute("src") || "";
      })()
    JS
    assert_includes hall, "ceremony-gateway", "ceremony world should use the gateway still"
  end

  def pair(name)
    [
      [ 320, 568, "phone-small" ],
      [ 360, 640, "phone-short" ],
      [ 390, 844, "phone" ],
      [ 430, 932, "phone-tall" ],
      [ 768, 1024, "ipad" ],
      [ 844, 390, "landscape-short" ],
      [ 1024, 768, "desktop" ],
      [ 1440, 900, "xl" ]
    ].each do |width, height, suffix|
      set_quiz_viewport(width, height)
      sleep 0.3
      shot("#{name}-#{suffix}")
      assert_quiz_viewport_fit!(suffix)
    end
    set_quiz_viewport(390, 844)
  end

  def set_quiz_viewport(width, height)
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width:,
      height:,
      deviceScaleFactor: 1,
      mobile: false
    )
  rescue NoMethodError
    page.current_window.resize_to(width, height)
  end

  def assert_quiz_viewport_fit!(viewport)
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var selectors = [
          "#street_quiz .quiz-hud",
          "#street_quiz .quiz-sheet",
          "#street_quiz .play-timer",
          "#street_quiz .street-shot-actions",
          "#street_quiz .choice-btn",
          "#street_quiz .quiz-bar",
          "#street_quiz .quiz-scripture",
          "#street_quiz .quiz-next",
          "body.is-street-play .home-menu-btn"
        ];
        return selectors.flatMap(function(selector) {
          return Array.from(document.querySelectorAll(selector)).map(function(el) {
            var r = el.getBoundingClientRect();
            return {
              selector: selector,
              left: r.left,
              top: r.top,
              right: r.right,
              bottom: r.bottom,
              height: r.height
            };
          });
        });
      })()
    JS
    width = page.evaluate_script("window.innerWidth")
    height = page.evaluate_script("window.innerHeight")
    geometry.each do |box|
      assert_operator box["left"], :>=, -2, "#{viewport}: #{box["selector"]} clips left"
      assert_operator box["top"], :>=, -2, "#{viewport}: #{box["selector"]} clips top"
      assert_operator box["right"], :<=, width + 2, "#{viewport}: #{box["selector"]} clips right"
      assert_operator box["bottom"], :<=, height + 2, "#{viewport}: #{box["selector"]} clips bottom"
      if box["selector"].end_with?(".choice-btn", ".quiz-bar", ".quiz-scripture", ".quiz-next", ".home-menu-btn")
        assert_operator box["height"], :>=, 44, "#{viewport}: interactive target is too short"
      end
    end
  end

  def visible_choice_count
    page.evaluate_script(<<~JS)
      (function() {
        var btns = Array.from(document.querySelectorAll("#street_quiz .choice-btn"));
        var h = window.innerHeight;
        return btns.filter(function(el) {
          var r = el.getBoundingClientRect();
          return r.top >= -8 && r.bottom <= (h + 8) && r.height > 20;
        }).length;
      })()
    JS
  end

  def assert_settled_choice_row!(bar)
    geo = bar.evaluate_script(<<~JS)
      (function() {
        var word = this.querySelector(".word");
        var meta = this.querySelector(".quiz-meta");
        var flag = this.querySelector(".quiz-flag");
        var fill = this.querySelector(".quiz-fill");
        var style = getComputedStyle(this);
        return {
          flex: style.flexDirection,
          bar: this.clientWidth,
          height: this.clientHeight,
          word: word.clientWidth,
          wordTop: word.offsetTop,
          wordHeight: word.offsetHeight,
          wordLeft: word.offsetLeft,
          metaTop: meta.offsetTop,
          flagLeft: flag ? flag.offsetLeft : null,
          flagColor: flag ? getComputedStyle(flag).color : "",
          yes: !!(flag && flag.classList.contains("is-yes")),
          fillH: fill ? fill.offsetHeight : 0,
          wordColor: getComputedStyle(word).color,
          bg: style.backgroundColor
        };
      }).call(this)
    JS
    assert_equal "row", geo["flex"]
    assert geo["flagLeft"], "settled choice needs a left mark"
    assert_operator geo["flagLeft"], :<, geo["wordLeft"]
    rgb = channel255(geo["flagColor"])
    if geo["yes"]
      assert_operator rgb[1], :>, rgb[0]
      assert_operator rgb[1], :>, 120
    else
      assert_operator rgb[0], :>, rgb[1]
    end
    assert_operator geo["word"].to_f / geo["bar"].to_f, :>=, 0.45
    assert_operator geo["metaTop"], :<, geo["wordTop"] + geo["wordHeight"]
    assert_operator geo["height"], :<=, 120
    assert_operator geo["fillH"], :>=, 20
    theme = find("#street_quiz")["data-quiz-theme"]
    word = channel255(geo["wordColor"])
    surface = channel255(geo["bg"])
    if theme == "light"
      assert_operator word[0], :<, 90
      assert_operator surface[0], :>, 180
    else
      assert_operator word[0], :>, 180
      assert_operator surface[0], :<, 90
    end
  end

  def channel255(color)
    if (m = color.to_s.match(/rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)/))
      return m.captures.first(3).map { |n| n.to_f.round }
    end
    if (m = color.to_s.match(/color\(\s*srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i))
      return m.captures.first(3).map { |n| (n.to_f * 255).round }
    end
    [0, 0, 0]
  end

  def assert_apex_above_sheet!
    metrics = page.evaluate_script(<<~JS)
      (function() {
        var apex = document.querySelector("#street_quiz .street-quiz-apex");
        var sheet = document.querySelector("#street_quiz .quiz-sheet") || document.querySelector("#street_quiz .play-sheet");
        var card = document.querySelector("#street_quiz .street-quiz-card");
        var overlay = document.querySelector("#street_quiz.is-overlay");
        if (!apex || !sheet) return null;
        var star = apex.getBoundingClientRect();
        var ivory = sheet.getBoundingClientRect();
        var x = Math.round(star.left + star.width / 2);
        var y = Math.round(star.top + star.height / 2);
        apex.style.pointerEvents = "auto";
        var stack = document.elementsFromPoint(x, y).map(function(el) {
          return el.className && String(el.className) || el.tagName;
        });
        apex.style.pointerEvents = "";
        return {
          overlay: !!overlay,
          overflow: overlay ? getComputedStyle(sheet).overflow : (card ? getComputedStyle(card).overflow : ""),
          protrude: ivory.top - star.top,
          starHeight: star.height,
          metal: getComputedStyle(apex, "::before").backgroundImage,
          stack: stack.slice(0, 6)
        };
      })()
    JS
    assert metrics, "quiz sheet should render an apex star"
    assert_equal "visible", metrics["overflow"], "quiz card overflow must not clip the apex star"
    assert_operator metrics["protrude"], :>=, 6, "apex star should sit on the quiz sheet hairline (#{metrics.inspect})"
    assert_operator metrics["starHeight"], :>=, 18, "apex star should be large enough to read (#{metrics.inspect})"
    assert_match(/linear-gradient/, metrics["metal"].to_s, "apex star should be gold-leaf metal, not a flat icon (#{metrics.inspect})")
    joined = Array(metrics["stack"]).join(" ")
    overlay_glass = metrics["overlay"] && !joined.match?(/street-quiz-apex|picto/)
    unless overlay_glass
      assert_match(/street-quiz-apex|picto/, joined, "apex star should paint above the still (#{metrics.inspect})")
      still_at = Array(metrics["stack"]).index { |name| name.to_s.include?("challenge-story") }
      apex_at = Array(metrics["stack"]).index { |name| name.to_s.include?("street-quiz-apex") || name.to_s.include?("picto") }
      if still_at && apex_at
        assert_operator apex_at, :<, still_at, "apex star must stack above the painting (#{metrics.inspect})"
      end
    end
  end

  def sheet_top
    page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector("#street_quiz .quiz-sheet") || document.querySelector("#street_quiz .play-sheet");
        if (!sheet) return 0;
        return sheet.getBoundingClientRect().top / window.innerHeight;
      })()
    JS
  end

  def score_top
    page.evaluate_script(<<~JS)
      (function() {
        var score = document.querySelector("#street_quiz .street-score");
        if (!score) return 1;
        return score.getBoundingClientRect().top / window.innerHeight;
      })()
    JS
  end

  def swipe(selector, dx:, dy:)
    page.execute_script(<<~JS, selector, dx, dy)
      var el = document.querySelector(arguments[0]);
      var r = el.getBoundingClientRect();
      var x = r.left + r.width * 0.5;
      var y = r.top + r.height * 0.4;
      var dx = arguments[1];
      var dy = arguments[2];
      var fire = function(type, cx, cy) {
        el.dispatchEvent(new PointerEvent(type, {
          bubbles: true, cancelable: true, pointerId: 1, pointerType: "touch",
          clientX: cx, clientY: cy
        }));
      };
      fire("pointerdown", x, y);
      fire("pointermove", x + dx * 0.35, y + dy * 0.35);
      fire("pointermove", x + dx, y + dy);
      fire("pointerup", x + dx, y + dy);
    JS
  end

  def wait_for_brush_fonts!
    page.evaluate_async_script(<<~JS)
      var done = arguments[0];
      if (!document.fonts || !document.fonts.load) { done(); return; }
      document.fonts.load("700 48px Kalam").then(function() { done(); }).catch(function() { done(); });
    JS
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    FileUtils.mkdir_p(TEMPLE_SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    temple_path = TEMPLE_SHOT_DIR.join("#{name}.png")
    FileUtils.cp(path, temple_path) if path.exist?
    warn "street-shot #{path}"
    warn "temple-shot #{temple_path}" if path.exist?
  end
end
