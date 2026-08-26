require "application_system_test_case"

class StreetQuizVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots")
  TEMPLE_SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "jugar rival chip on play shot" do
    page.current_window.resize_to(390, 844)
    sign_in_fixture_person!(people(:pili))
    assert_no_selector "#profile_gate"
    assert_selector ".street-play-cta", wait: 5
    find(".street-play-cta").click
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
    assert_selector ".street-shot-rival"
    assert_selector ".street-shot-rival-gap, .street-rival-gap-pill"
    sleep 0.5
    shot("01-ask-rival-phone")
  end

  test "hub league strip with signed-in profile" do
    page.current_window.resize_to(390, 844)
    person = people(:pili)
    sign_in_fixture_person!(person)
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
    assert_selector ".street-league-panel.is-avatars"
    assert_selector ".street-league-slot", minimum: 3
    assert_selector ".street-xp-bar"
    assert_selector ".street-hub-lockup-name", text: "Noche Live"
    assert_selector ".street-hub-lockup-star"
    assert_selector ".street-temple-pill"
    assert_selector ".street-map-legend"
    assert_selector ".street-map-legend-rose"
    assert_selector ".street-rank-banner"
    assert_selector ".street-hub-kicker"
    assert_selector ".street-map-track .street-card.is-pack.is-locked"
    assert_selector ".street-map-track .street-card.is-pack.is-current"
    assert_selector ".street-map-track .street-card.is-pack.is-finished"
    assert_selector ".street-map-path.is-rope .street-map-rope", minimum: 2
    assert_selector ".street-card.is-pack.is-finished"
    assert_selector ".street-card.is-pack.is-current"
    assert_selector ".street-card.is-pack.is-locked"
    page.execute_script("window.scrollTo(0, 0)")
    sleep 0.6
    find(".home-menu-btn").click
    assert_selector "details.home-menu[open] .home-menu-nav"
    assert_selector ".home-menu-me"
    assert_selector ".home-menu-row", text: I18n.t("street.history_menu")
    assert_no_selector ".home-menu-row", text: I18n.t("street.nav_hub")
    shot("hub-menu-phone")
    find(".home-menu-btn").click
    assert_no_selector "details.home-menu[open]"
    assert_above_hub_dock ".street-card.is-pack.is-finished"
    assert_above_hub_dock ".street-card.is-pack.is-current"
    assert_above_hub_dock ".street-card.is-pack.is-locked"
    assert_above_hub_dock ".street-league-panel"
    assert_chrome_tools_clear_hub_dock
    shot("hub-league-phone")
    shot("hub-phone")
    page.current_window.resize_to(1280, 800)
    assert_hub_chrome_on_column
    shot("hub-desktop")
    page.current_window.resize_to(390, 844)
  end

  test "hub map and jugar reel flow" do
    page.current_window.resize_to(390, 844)
    visit root_path
    dismiss_profile_gate!
    assert_selector "#street_world.street-world"
    assert_selector ".street-hub-lockup-name", text: "Noche Live"
    assert_selector ".street-hub-lockup-star"
    assert_selector ".street-temple-pill"
    assert_selector ".street-map-legend"
    assert_selector ".street-map-legend-rose"
    assert_selector ".street-hub-kicker"
    assert_selector ".street-hub-nav-item", count: 5
    assert_selector ".street-map-path.is-rope"
    assert_selector ".street-map-path.is-rope .street-map-rope"
    assert_selector ".street-map-track .street-card.is-pack.is-locked"
    assert_selector ".street-card.is-pack.is-current"
    assert_selector ".street-pack-beacon"
    assert_selector ".street-play-cta"
    assert_no_selector "#street_quiz"
    page.execute_script("window.scrollTo(0, 0)")
    sleep 0.8
    assert_above_hub_dock ".street-card.is-pack.is-locked"
    assert_chrome_tools_clear_hub_dock
    shot("hub-guest-phone")
    page.current_window.resize_to(390, 844)
    click_button I18n.t("street.world_play")
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
    assert_selector ".street-level-rail"
    assert_no_selector ".street-map"
    pair("01-hub-jugar")
  end

  test "hub rank up ring on player card" do
    page.current_window.resize_to(390, 844)
    sign_in_street_profile!
    visit root_path(rank_up: 1)
    assert_selector ".street-card.is-player.is-rank-up"
    sleep 0.6
    shot("rank-up-phone")
  end

  test "hub pack unlock animation" do
    page.current_window.resize_to(390, 844)
    visit root_path
    dismiss_profile_gate!
    next_pack = QuizDefinition.catalog.pack_ids.second
    visit root_path(unlock: next_pack)
    assert_selector "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    sleep 0.5
    shot("hub-pack-unlock-phone")
  end

  test "pack ceremony on last question" do
    page.current_window.resize_to(390, 844)
    QuizRun.where(status: "open").update_all(status: "finished")
    visit root_path
    dismiss_profile_gate!
    click_button I18n.t("street.world_play")
    assert_selector "#street_quiz"
    run = QuizRun.open_runs.order(:id).last
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    seed_ceremony_board!(run.pack_id)
    question = pack.question_at(10)
    run.update!(position: 10, score: 80, ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: question.correct_choice)
    visit jugar_path
    assert_selector ".quiz-board.is-settled"
    click_button I18n.t("quiz.next")
    assert_selector ".street-ceremony[data-street-motion-sequence-value='packComplete']"
    assert_selector "#street_quiz.is-ceremony-immersive"
    assert_ceremony_temple_scrim
    sleep 1.8
    wait_for_brush_fonts!
    assert_in_viewport ".street-ceremony-map"
    assert_in_viewport ".street-challenge-btn", slop: 48
    shot("ceremony-phone")
    page.current_window.resize_to(1280, 800)
    shot("jugar-ceremony-desktop")
    page.current_window.resize_to(390, 844)
  end

  test "hub profile wizard on first visit" do
    page.current_window.resize_to(390, 844)
    visit root_path
    assert_selector "#profile_gate.street-wizard"
    sleep 0.6
    shot("wizard-phone")
  end

  test "hub duel banner with pending challenge" do
    duel = street_duels(:pending_challenge)
    page.current_window.resize_to(390, 844)
    sign_in_street_rival!
    visit root_path(desafio: duel.token)
    assert_selector ".street-duel-banner"
    assert_selector ".street-duel-vs-mark", text: "VS"
    sleep 0.5
    shot("duel-banner-phone")
  end

  test "challenge button on pack ceremony" do
    page.current_window.resize_to(390, 844)
    sign_in_street_profile!
    QuizRun.where(status: "open").update_all(status: "finished")
    visit root_path
    click_button I18n.t("street.world_play")
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
    assert_selector ".street-ceremony-plinth"
    assert_selector ".street-challenge-btn"
    assert_no_selector ".street-card.is-share"
    sleep 1.8
    wait_for_brush_fonts!
    assert_in_viewport ".street-ceremony-map"
    assert_in_viewport ".street-challenge-btn", slop: 48
    shot("ceremony-challenge-phone")
  end

  test "street quiz sheet type miss ticks and swipe" do
    page.current_window.resize_to(390, 844)
    ready_street_quiz!
    assert_selector "#street_quiz[data-controller~=story]"
    assert_no_selector ".story-ticks"
    assert_no_selector ".story-close"
    assert_selector ".play-sheet[data-sheet-snap=mid]"
    assert_selector ".street-quiz-lockup-name", text: "Noche Live"
    assert_selector ".street-quiz-apex"
    assert_selector ".street-quiz-rule"
    assert_no_selector ".quiz-pack"
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
    assert_selector ".quiz-bar.is-correct.is-right"
    assert_selector ".quiz-bar.is-wrong.is-miss"
    assert_selector ".quiz-flag"
    assert_selector "a.quiet-link .quiz-cite"
    assert_selector ".play-sheet[data-sheet-snap=open]"
    assert_selector ".street-score span", text: "0"
    assert_no_selector ".street-score.is-tick"
    pair("02-miss")
    bar = page.first(".quiz-bar")
    word = bar.find(".word")
    meta = bar.find(".quiz-meta")
    widths = bar.evaluate_script("({ bar: this.clientWidth, word: this.querySelector('.word').clientWidth, wordTop: this.querySelector('.word').offsetTop, metaTop: this.querySelector('.quiz-meta').offsetTop })")
    assert_operator widths["word"].to_f / widths["bar"].to_f, :>=, 0.88
    assert_operator widths["metaTop"], :>=, widths["wordTop"]

    click_button I18n.t("quiz.next")
    assert_selector ".choice-btn"
    assert_selector ".play-sheet[data-sheet-snap=mid]"
    assert_selector ".street-score span", text: "0"
    assert_no_selector "#street_quiz .btn.btn-gold"
    pair("02b-next-ask")
    first(".choice-btn").click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".play-sheet[data-sheet-snap=open]"
    assert_selector ".street-score"
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
    pair("06-timed")
  end

  test "settled four bars keep next in the dock" do
    page.current_window.resize_to(390, 844)
    ready_street_quiz!
    run = QuizRun.order(:id).last
    question = QuizDefinition.catalog.find_pack("coronas").question_at(2)
    run.update!(pack_id: "coronas", position: 2, score: 0, ends_at: nil, status: "open")
    visit jugar_path

    wrong = page.all(".choice-btn").find { |btn| btn["data-choice-key"] != question.correct_choice }
    wrong.click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".quiz-bar", count: 4
    bar = page.first(".quiz-bar")
    widths = bar.evaluate_script("({ bar: this.clientWidth, word: this.querySelector('.word').clientWidth, wordTop: this.querySelector('.word').offsetTop, metaTop: this.querySelector('.quiz-meta').offsetTop })")
    assert_operator widths["word"].to_f / widths["bar"].to_f, :>=, 0.88
    assert_operator widths["metaTop"], :>=, widths["wordTop"]
    assert_selector ".street-quiz-dock .quiz-next"
    assert_in_viewport ".street-quiz-dock .quiz-next"
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

  def ready_street_quiz!
    visit root_path
    dismiss_profile_gate!
    click_button I18n.t("street.world_play") if page.has_button?(I18n.t("street.world_play"), wait: 1)
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
  end

  def pick_ward_in_gate!
    return unless page.has_css?("#profile_gate", wait: 2)

    featured = Ward.find_by(code: Ward::FEATURED_CODE)
    return unless featured && page.has_button?(featured.name, wait: 1)

    within("#profile_gate") { click_button featured.name }
  end

  def clear_street_session!
    page.driver.browser.manage.delete_all_cookies
  end

  def sign_in_fixture_person!(person)
    clear_street_session!
    visit root_path
    pick_ward_in_gate!
    unless page.has_css?("#profile_gate", wait: 2)
      visit root_path(ficha: 1)
    end
    assert_selector "#profile_gate", wait: 5

    within("#profile_gate") do
      if page.has_button?(person.given_name, wait: 1)
        click_button person.given_name
      else
        fill_in "gate_name", with: person.given_name
        fill_in "favorite_year", with: person.favorite_year
        click_button I18n.t("street.gate_create")
      end
    end
    assert_no_selector "#profile_gate"
  end

  def sign_in_street_rival!(name: "Carmen")
    sign_in_fixture_person!(people(:carmen_garcia))
  end

  def sign_in_street_profile!(name: "RankTest", year: "2015")
    clear_street_session!
    visit root_path
    pick_ward_in_gate!
    return unless page.has_css?("#profile_gate", wait: 2)

    within("#profile_gate") do
      fill_in "gate_name", with: name
      fill_in "favorite_year", with: year
      click_button I18n.t("street.gate_create")
    end
    assert_no_selector "#profile_gate"
  end

  def dismiss_profile_gate!
    clear_street_session!
    visit root_path
    pick_ward_in_gate!
    return unless page.has_css?("#profile_gate", wait: 2)

    within("#profile_gate") { click_button I18n.t("street.continue_guest") }
    assert_no_selector "#profile_gate"
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

  def assert_above_hub_dock(selector)
    visible = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        var cta = document.querySelector(".street-play-cta");
        var dock = document.querySelector(".street-world-dock");
        var limit = cta ? cta.getBoundingClientRect().top
          : (dock ? dock.getBoundingClientRect().top : window.innerHeight);
        return r.top >= -8 && r.bottom <= (limit + 8) && r.height > 0;
      })()
    JS
    assert visible, "#{selector} should sit above JUGAR on the first fold"
  end

  def assert_chrome_tools_clear_hub_dock
    clear = page.evaluate_script(<<~JS)
      (function() {
        var tools = document.querySelector(".chrome-tools");
        var cta = document.querySelector(".street-play-cta");
        if (!tools || !cta) return false;
        var t = tools.getBoundingClientRect();
        var c = cta.getBoundingClientRect();
        return t.height > 0 && t.bottom <= c.top - 4;
      })()
    JS
    assert clear, "mute/lang should sit above JUGAR, not on the dock"
  end

  def assert_hub_chrome_on_column
    aligned = page.evaluate_script(<<~JS)
      (function() {
        var world = document.querySelector("#street_world");
        var menu = document.querySelector(".home-menu");
        var trophy = document.querySelector(".street-hub-tool-trophy");
        if (!world || !menu || !trophy) return false;
        var w = world.getBoundingClientRect();
        var m = menu.getBoundingClientRect();
        var t = trophy.getBoundingClientRect();
        return m.left >= w.left - 12 && t.right <= w.right + 12;
      })()
    JS
    assert aligned, "gear and trophy should pin to the hub column, not the window corners"
  end

  def assert_ceremony_temple_scrim
    assert_selector "#street_quiz.is-ceremony-immersive"
    assert_selector ".street-ceremony-lockup"
    assert_selector ".street-ceremony-lockup-live"
    assert_selector ".street-ceremony-filigree"
    assert_selector ".street-ceremony-lockup-mark-img"
    assert_selector ".street-ceremony-monument"
    assert_selector ".street-ceremony-trophy"
    assert_selector ".street-ceremony-slab"
    assert_selector ".street-ceremony-plinth"
    assert_selector ".street-ceremony-laurel"
    assert_selector ".street-ceremony-score-label"
    assert_selector ".street-ceremony-chest-img"
    assert_selector ".street-ceremony-map"
    assert_selector ".street-challenge-btn"
    assert_selector ".street-ceremony-best-row", minimum: 3
    assert_no_selector ".street-ceremony-column-scrim"
    hall = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector("#street_quiz");
        if (!el) return "";
        return getComputedStyle(el).backgroundImage || "";
      })()
    JS
    assert_includes hall, "marble-hall-victory", "ceremony hall should use the victory plate"
    shot_hidden = page.evaluate_script(<<~JS)
      (function() {
        var shot = document.querySelector("#street_quiz .play-shot");
        if (!shot) return true;
        return getComputedStyle(shot).opacity === "0" || shot.getBoundingClientRect().height === 0;
      })()
    JS
    assert shot_hidden, "pack still should be hidden behind temple hall"
  end

  def pair(name)
    page.current_window.resize_to(390, 844)
    shot("#{name}-phone")
    page.current_window.resize_to(1280, 800)
    shot("#{name}-desktop")
    page.current_window.resize_to(390, 844)
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

  def sheet_top
    page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector("#street_quiz .play-sheet");
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
