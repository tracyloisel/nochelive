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

  test "a signed-in member sees their league position and rival gap" do
    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward)
    assert screen.league
    assert_operator screen.league.rank, :>=, 1
    assert_operator screen.league.players, :>=, 1
    assert_kind_of Array, screen.league.recent_gains
  end

  test "league pulse exposes recent positive ward gains without inventing an unread state" do
    question = QuizDefinition.catalog.find_pack("coronas").questions.first
    run = QuizRun.create!(
      person: @pili,
      device_digest: "hub-recent-gain",
      pack_id: question.pack_id,
      position: 1,
      score: 17,
      status: "finished",
      opened_at: 1.hour.ago
    )
    gain = travel_to(1.hour.ago) do
      run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: question.id,
        choice_key: question.correct_choice,
        correct: true,
        points_awarded: 17
      )
    end

    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward, at: Time.current)

    assert_equal @pili.given_name, screen.league.recent_gains.first.name
    assert_equal 17, screen.league.recent_gains.first.points
    assert_equal gain.created_at.to_i, screen.league.recent_gains.first.at.to_i
  end

  test "a guest never sees a league position" do
    screen = Hubs::Screen.call(device_digest: @digest)
    assert_nil screen.league
  end

  test "open run keeps Jouer on GET jugar and remaining curve points" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    screen = Hubs::Screen.call(device_digest: @digest, open_run: run)
    assert_equal :get, screen.hero.method
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

  test "voyage is previous current next and Jouer stays on current pack" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    screen = Hubs::Screen.call(device_digest: @digest)
    assert_equal QuizDefinition.catalog.find_pack("coronas").copy(:title), screen.voyage.previous.title
    assert_equal QuizDefinition.catalog.find_pack("coronas").copy(:kicker), screen.voyage.previous.kicker
    assert_equal screen.voyage.current.title, screen.hero.title
    assert_equal screen.hero.kicker, screen.voyage.current.kicker
    assert_equal screen.hero.path, screen.voyage.current.path
    assert_equal :post, screen.voyage.previous.method
    assert screen.voyage.previous.path.present?
    assert_nil screen.voyage.next.path
  end

  test "current voyage slide carries the overlay copy Jouer needs" do
    screen = Hubs::Screen.call(device_digest: @digest)
    slide = screen.voyage.current
    assert_equal screen.hero.kicker, slide.kicker
    assert_equal screen.hero.lede, slide.lede
    assert_equal screen.hero.step_n, slide.step_n
    assert_equal screen.hero.reward, slide.reward
    assert_equal screen.hero.path, slide.path
    assert_equal screen.hero.still, slide.still
    assert_equal :post, slide.method
  end

end
