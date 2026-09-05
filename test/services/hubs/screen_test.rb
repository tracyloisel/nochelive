require "test_helper"

class Hubs::ScreenTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("hub-screen")
    @ward = wards(:demo)
    @pili = people(:pili)
  end

  test "guest hero is the first pack with honest remaining points" do
    screen = Hubs::Screen.call(device_digest: @digest)
    assert screen.player.guest
    assert_equal 0, screen.player.crowns
    assert_equal 1, screen.hero.step_n
    assert_equal 10, screen.hero.step_total
    assert_equal Quizzes::StreakReward.max_pack_score, screen.hero.reward
    assert_equal :post, screen.hero.method
    assert_equal :start, screen.hero.state
    assert_equal :ward_missing, screen.live.state
    assert_equal Rails.application.routes.url_helpers.street_profile_path(quick: 1, fresh: 1, ward_next: 1),
      screen.live.ward_pick_path
    assert_equal generated_media_src("media/church/worship.jpg", format: "webp"), screen.live.still
    assert_equal screen.backdrop.theme.mode, screen.live.theme_mode
    assert_equal screen.backdrop.theme.atmosphere, screen.live.theme_atmosphere
    assert screen.backdrop.theme.mode.in?(%w[light dark])
  end

  test "the current weekly programme exposes individual localized reading cards" do
    week = create_current_weekly_program!
    I18n.with_locale(:fr) do
      screen = Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward)
      study = screen.study

      assert study
      assert_equal week.id, study.week.id
      assert_equal week.published_quiz.readings(:fr).map { |reading| reading.fetch("study") }.uniq,
        study.weekly_reading_cards.map(&:study)
      expected_titles = week.published_quiz.readings(:fr).map do |reading|
        reference = Scriptures::Reference.from_study(study: reading.fetch("study"), locale: :fr, verse: 1)
        "#{reference.book_label} #{reference.chapter}"
      end.uniq
      assert_equal expected_titles, study.weekly_reading_cards.map(&:title)
      assert study.weekly_reading_cards.all? { |card| card.study_unit_id == study.week.id }
    end
  end

  test "the Hub picks the active published week over later draft and future programmes" do
    week = create_current_weekly_program!
    StudyProgram.create!(
      slug: "hub-weekly-draft-#{SecureRandom.hex(6)}",
      title: "Brouillon futur",
      year: Date.current.year + 11,
      canon: "old_testament",
      locale: "fr",
      status: "draft",
      source_url: "https://example.test/hub-weekly-draft"
    )
    future_program = StudyProgram.create!(
      slug: "hub-weekly-future-#{SecureRandom.hex(6)}",
      title: "Programme futur",
      year: Date.current.year + 12,
      canon: "old_testament",
      locale: "fr",
      status: "published",
      source_url: "https://example.test/hub-weekly-future"
    )
    future_program.study_units.create!(
      slug: "week-future",
      kind: "week",
      position: 1,
      title: "Une semaine future",
      source_url: "https://example.test/hub-weekly-future/week",
      starts_on: 6.months.from_now.to_date.beginning_of_week,
      ends_on: 6.months.from_now.to_date.end_of_week,
      scripture_refs: [ "Psaumes" ],
      status: "published"
    )

    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward)

    assert_equal week.id, screen.study.week.id
  end

  private

    def create_current_weekly_program!
      program = StudyProgram.create!(
        slug: "hub-weekly-screen-#{SecureRandom.hex(6)}",
        title: "Viens et suis-moi #{Date.current.year}",
        year: Date.current.year + 10,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/hub-weekly"
      )
      week = program.study_units.create!(
        slug: "week-current",
        kind: "week",
        position: 1,
        title: "Cette semaine : Psaumes",
        source_url: "https://example.test/hub-weekly/current",
        starts_on: Date.current.beginning_of_week,
        ends_on: Date.current.end_of_week,
        scripture_refs: [ "Psaumes" ],
        status: "published"
      )
      content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml")).dig("quizzes", 0, "content")
      week.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json),
        published_at: Time.current
      )
      week
    end

  public

  test "ward discovery live card keeps neutral chapel art and inherits the hub background theme" do
    Hubs::Backdrop.entries = [
      {
        "id" => "dark-coronas",
        "image" => "quizzes/coronas/ungio_david.jpg",
        "tags" => [ "coronas" ],
        "theme" => { "mode" => "dark", "atmosphere" => "solemn", "accent" => "gold" }
      }
    ]

    screen = Hubs::Screen.call(device_digest: @digest)

    assert_equal :ward_missing, screen.live.state
    assert_equal generated_media_src("media/church/worship.jpg", format: "webp"), screen.live.still
    assert_equal "dark", screen.backdrop.theme.mode
    assert_equal "dark", screen.live.theme_mode
    assert_equal "solemn", screen.live.theme_atmosphere
  ensure
    Hubs::Backdrop.reset!
  end

  test "signed in player can pick a ward without creating another profile" do
    @pili.update!(ward: nil)
    screen = Hubs::Screen.call(device_digest: @digest, person: @pili)

    assert_equal Rails.application.routes.url_helpers.search_path(cambiar: 1), screen.live.ward_pick_path
  end

  test "xp uses rank thresholds not a fake 1000 bar" do
    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward)
    assert_equal 95, screen.player.xp_now
    assert_equal 110, screen.player.xp_next
    assert_equal 95, screen.player.crowns
    assert_equal 3, screen.player.level
    refute_equal 1000, screen.player.xp_next
  end

  test "a signed-in player keeps their real score without a Rama while league data stays off Home" do
    @pili.update!(ward: nil)
    expected_score = Quizzes::Leaderboard.total_score(person: @pili)

    screen = Hubs::Screen.call(device_digest: @digest, person: @pili)

    assert_operator expected_score, :positive?
    assert_equal expected_score, screen.player.crowns
    assert_equal expected_score, screen.player.xp_now
    assert_equal @pili.given_name, screen.player.name
    refute_respond_to screen, :league
    refute_includes Hubs::Screen::Result.members, :league
  end

  test "open run keeps Jouer on GET jugar and remaining curve points" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    screen = Hubs::Screen.call(device_digest: @digest, open_run: run)
    assert_equal :get, screen.hero.method
    assert_equal :resume, screen.hero.state
    assert_equal Rails.application.routes.url_helpers.jugar_path, screen.hero.path
    assert_equal 1, screen.hero.step_n
    assert_equal Quizzes::StreakReward.max_pack_score, screen.hero.reward
  end

  test "settled question is removed from the live remaining reward" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)

    screen = Hubs::Screen.call(device_digest: @digest, open_run: run.reload)

    assert_equal 84, screen.hero.reward
    refute_equal Quizzes::StreakReward.max_pack_score, screen.hero.reward
  end

  test "the resumable Light question drives both the Hub theme and hero still" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    run.update!(position: 5)

    screen = Hubs::Screen.call(device_digest: @digest, open_run: run.reload)

    assert_equal 5, screen.hero.step_n
    assert_equal "light", screen.backdrop.theme.mode
    assert_equal "salt-lake-temple-dawn", screen.backdrop.id
    assert_equal "hub.hero.salt-lake-temple-dawn", screen.backdrop.hero
    assert_equal generated_media_src("media/quizzes/coronas/salomon_templo.jpg", format: "webp"), screen.hero.still
  end

  test "live states follow the clock without a three-day countdown" do
    game_sessions(:david).update_columns(status: "finished", closed_at: Time.current)
    night = game_sessions(:elias)
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 3.days)
    assert_equal :scheduled, screen.live.state
    assert_equal night.quiz_packs.map { |pack| pack.copy(:title) }.join(" · "), screen.live.title

    soon = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 30.hours)
    assert_equal :soon, soon.live.state

    imminent = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 8.hours)
    assert_equal :imminent, imminent.live.state
  end

  test "the next Noche Live title follows the active player locale" do
    game_sessions(:david).update_columns(status: "finished", closed_at: Time.current)
    night = Nights::Start.call(
      ward: @ward,
      quiz_ids: %w[exp_psalms_disappearing_voice exp_psalms_nameless_king],
      starts_at: 1.day.from_now
    )

    screen = I18n.with_locale(:es) do
      Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward, at: Time.current)
    end

    assert_equal "La voz que desaparece · El Rey sin nombre", screen.live.title
    assert_equal night.quiz_pack_ids, night.reload.quiz_pack_ids
  end

  test "playing night is LIVE with a join path" do
    night = game_sessions(:david)
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward)
    assert_equal :playing, screen.live.state
    assert screen.live.still.present?
    assert_equal Rails.application.routes.url_helpers.night_path(night.code), screen.live.join_path
  end

  test "the clock overrides stale lifecycle labels" do
    at = Time.current
    game_sessions(:david).update!(status: "playing", starts_at: 20.hours.from_now)
    game_sessions(:elias).update!(status: "lobby", starts_at: 21.hours.from_now)

    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at:)

    assert_equal :imminent, screen.live.state
    assert_equal game_sessions(:david).starts_at, screen.live.starts_at
    assert_nil screen.live.join_path
  end

  test "live card uses the first quiz artwork and canonical path" do
    game_sessions(:david).update_columns(status: "finished", closed_at: Time.current)
    night = game_sessions(:elias)
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 3.days)
    chrome = Quizzes::Chrome.call(question: night.primary_quiz_pack.question_at(1))

    expected = generated_media_src("media/#{night.primary_quiz_pack.question_at(1).presentation.fetch("image")}", format: "webp")
    assert_equal :scheduled, screen.live.state
    assert_equal expected, screen.live.still
    assert_equal chrome.mode, screen.live.theme_mode
    assert_equal chrome.atmosphere, screen.live.theme_atmosphere
    refute_respond_to screen.live, :hosts
  end

  test "a completed pack gives the Home one explicit next adventure" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    screen = Hubs::Screen.call(device_digest: @digest)
    next_pack = QuizDefinition.catalog.find_pack("placas")

    assert_equal :start, screen.hero.state
    assert_equal next_pack.copy(:title), screen.hero.title
    assert_equal :post, screen.hero.method
    assert_equal Rails.application.routes.url_helpers.street_pack_start_path(next_pack.id), screen.hero.path
    refute_respond_to screen, :voyage
  end

  test "the active quiz resolves and keeps its approved DailyDiscovery with its explicit clock" do
    zone = Time.find_zone!("Europe/Madrid")
    starts_on = Date.new(2044, 8, 29)
    _week, quiz = create_daily_editorial_week!(starts_on:)
    at = zone.local(2044, 8, 31, 12)
    @pili.update!(ward: nil)

    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, at:)

    assert_equal quiz.id, screen.study.week.published_quiz.id
    assert_equal "daily-03", screen.study.daily_discovery.id
    assert_equal zone.name, screen.study.daily_discovery.time_zone
    assert_equal Date.new(2044, 8, 31), screen.study.daily_discovery.scheduled_on
    assert_equal :daily_discovery, screen.today.kind
    assert_equal screen.study.daily_discovery.cta_label, screen.today.action_label
  end

  test "the quiz clock selects its Monday discovery while the UTC server is still on Sunday" do
    starts_on = Date.new(2044, 8, 29)
    week, _quiz = create_daily_editorial_week!(starts_on:)
    at = Time.utc(2044, 8, 28, 22, 30)
    @pili.update!(ward: nil)

    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, at:)

    assert_equal week.id, screen.study.week.id
    assert_equal "daily-01", screen.study.daily_discovery.id
    assert_equal starts_on, screen.study.daily_discovery.scheduled_on
    assert_equal :daily_discovery, screen.today.kind
  end

  test "the Hub fails daily editorial closed when the dated row loses approval" do
    zone = Time.find_zone!("Europe/Madrid")
    starts_on = Date.new(2044, 8, 29)
    _week, quiz = create_daily_editorial_week!(starts_on:)
    changed = quiz.content.deep_dup
    changed.fetch("daily_discoveries").first.fetch("truth_gate")["status"] = "REJECT"
    quiz.update_columns(content: changed, content_digest: StudyQuizVersion.content_digest_for(changed))
    @pili.update!(ward: nil)

    screen = Hubs::Screen.call(
      device_digest: @digest,
      person: @pili,
      at: zone.local(2044, 8, 29, 12)
    )

    assert_nil screen.study.daily_discovery
    assert_equal :expedition, screen.today.kind
    assert_nil screen.today.action_label
  end

  test "a signed-in player without a Rama or current programme gets a fallback distinct from the hero" do
    @pili.update!(ward: nil)

    screen = Hubs::Screen.call(
      device_digest: @digest,
      person: @pili,
      at: Time.zone.local(1900, 1, 2, 12)
    )

    assert_equal :ward_missing, screen.live.state
    assert_nil screen.study
    assert_equal :fallback, screen.today.kind
    assert_nil screen.today.scheduled_on
    assert_nil screen.today.title
    assert_nil screen.today.path
    assert_nil screen.today.method
    assert_nil screen.today.action_label
  end

  test "Screen reuses one Live event set and study projection for Today and its result" do
    service = Hubs::Screen.new(device_digest: @digest)
    live = Hubs::Screen::Live.new(state: :none)
    study = Hubs::Screen::Study.new
    hero = Hubs::Screen::Hero.new(title: "Aventure", path: "/jugar", method: :get, state: :resume)
    events = [ Object.new ]
    today = Hubs::Today::Item.new(kind: :fallback)
    counts = Hash.new(0)
    received = nil

    service.define_singleton_method(:build_live) { counts[:live] += 1; live }
    service.define_singleton_method(:build_study) { counts[:study] += 1; study }
    service.define_singleton_method(:build_hero) { hero }

    event_resolver = lambda do |**|
      counts[:events] += 1
      events
    end
    today_resolver = lambda do |**arguments|
      received = arguments
      today
    end

    original_events = Hubs::RamaEvents.method(:call)
    original_today = Hubs::Today.method(:call)
    Hubs::RamaEvents.define_singleton_method(:call, &event_resolver)
    Hubs::Today.define_singleton_method(:call, &today_resolver)
    result = service.call

    assert_equal({ live: 1, study: 1, events: 1 }, counts)
    assert_same live, result.live
    assert_same study, result.study
    assert_same events, result.rama_events
    assert_same live, received.fetch(:live)
    assert_same study, received.fetch(:study)
    assert_same events, received.fetch(:rama_events)
    assert_not received.key?(:date)
    assert_same today, result.today
  ensure
    Hubs::RamaEvents.define_singleton_method(:call, original_events) if original_events
    Hubs::Today.define_singleton_method(:call, original_today) if original_today
  end

  private

    def create_daily_editorial_week!(starts_on:)
      program = StudyProgram.create!(
        slug: "hub-daily-editorial-#{SecureRandom.hex(6)}",
        title: "Programme quotidien",
        year: starts_on.year,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/hub-daily-editorial"
      )
      week = program.study_units.create!(
        slug: "week-daily",
        kind: "week",
        position: 1,
        title: "Psaumes",
        source_url: "https://example.test/hub-daily-editorial/week",
        starts_on:,
        ends_on: starts_on + 6.days,
        scripture_refs: [ "Psaumes" ],
        status: "published"
      )
      content = {
        "questions" => [],
        "readings" => [],
        "expedition" => {
          "id" => "hub-daily-psalms",
          "title" => Locale::AVAILABLE.index_with { |locale| "Expedition #{locale}" },
          "pack_ids" => [ "psalms_living_god" ]
        },
        "daily_discoveries" => 7.times.map do |index|
          daily_editorial_row(index:, starts_on:)
        end
      }
      quiz = week.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: StudyQuizVersion.content_digest_for(content),
        published_at: Time.find_zone!("Europe/Madrid").local(2044, 8, 28, 12)
      )
      [ week, quiz ]
    end

    def daily_editorial_row(index:, starts_on:)
      number = index + 1
      {
        "id" => format("daily-%02d", number),
        "kind" => index == 6 ? "contemplation" : "discovery",
        "revision" => 1,
        "scheduled_on" => (starts_on + index.days).iso8601,
        "timezone" => "Europe/Madrid",
        "status" => "approved",
        "pack_id" => index == 6 ? nil : "psalms_living_god",
        "reference" => "ot/ps/102",
        "references" => [ "ot/ps/102" ],
        "claim_ids" => [ format("exeg-%03d", number) ],
        "depiction_mode" => "symbolic_atmosphere",
        "certainty" => "ATTESTE",
        "artwork_key" => "scripture.library.daily.#{number}",
        "light_family" => "celestial_dark",
        "motion" => "still",
        "audio" => "silent",
        "truth_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
        "experience_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
        "copy" => Locale::AVAILABLE.index_with do |locale|
          {
            "eyebrow" => "#{locale} aujourd'hui #{number}",
            "title" => "#{locale} titre #{number}",
            "setup" => "#{locale} contexte #{number}",
            "question" => "#{locale} question #{number}",
            "cta_label" => "#{locale} ouvrir #{number}"
          }
        end,
        "alt" => Locale::AVAILABLE.index_with { |locale| "Illustration #{locale} #{number}" },
        "disclosure" => Locale::AVAILABLE.index_with { |locale| "Composition #{locale} #{number}" }
      }
    end
end
