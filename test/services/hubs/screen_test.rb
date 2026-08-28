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
    assert_equal "coronas", screen.hero.pack_id
    assert_equal 1, screen.hero.step_n
    assert_equal 10, screen.hero.step_total
    assert_equal QuizDefinition::CURVE_POINTS.sum, screen.hero.reward
    assert_equal :post, screen.hero.method
    assert_equal :ward_missing, screen.live.state
    assert_equal Rails.application.routes.url_helpers.street_profile_path(quick: 1, fresh: 1, ward_next: 1),
      screen.live.ward_pick_path
    assert_equal screen.backdrop.theme.mode, screen.live.theme_mode
    assert_equal screen.backdrop.theme.atmosphere, screen.live.theme_atmosphere
    assert_nil screen.challenge
    assert_equal [], screen.online
    assert screen.backdrop.theme.mode.in?(%w[light dark])
    assert_operator screen.progress.study_completed, :>=, 0
    assert_operator screen.progress.study_total, :>=, screen.progress.study_completed
  end


  test "live card without its own image inherits the hub background theme" do
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

  test "open run keeps Jouer on GET jugar and remaining curve points" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    screen = Hubs::Screen.call(device_digest: @digest, open_run: run)
    assert_equal :get, screen.hero.method
    assert_equal Rails.application.routes.url_helpers.jugar_path, screen.hero.path
    assert_equal 1, screen.hero.step_n
    assert_equal QuizDefinition::CURVE_POINTS.sum, screen.hero.reward
  end

  test "settled question is removed from the live remaining reward" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)

    screen = Hubs::Screen.call(device_digest: @digest, open_run: run.reload)

    assert_equal QuizDefinition::CURVE_POINTS.drop(1).sum, screen.hero.reward
    refute_equal QuizDefinition::CURVE_POINTS.sum, screen.hero.reward
  end

  test "live states follow the clock without a three-day countdown" do
    game_sessions(:david).update!(status: "finished")
    night = game_sessions(:elias)
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 3.days)
    assert_equal :scheduled, screen.live.state
    assert_equal night.theme_title, screen.live.title

    soon = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 30.hours)
    assert_equal :soon, soon.live.state

    imminent = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 8.hours)
    assert_equal :imminent, imminent.live.state
  end

  test "playing night is LIVE with a join path" do
    night = game_sessions(:david)
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward)
    assert_equal :playing, screen.live.state
    assert screen.live.still.present?
    assert_equal Rails.application.routes.url_helpers.night_name_path(night.code), screen.live.join_path
  end

  test "a future night accidentally marked playing cannot hide the scheduled lobby" do
    at = Time.current
    game_sessions(:david).update!(status: "playing", starts_at: 20.hours.from_now)
    scheduled = game_sessions(:elias)
    scheduled.update!(status: "lobby", starts_at: 21.hours.from_now)

    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at:)

    assert_equal :imminent, screen.live.state
    assert_equal scheduled.starts_at, screen.live.starts_at
    assert_nil screen.live.join_path
  end

  test "live card names the elders and uses dedicated game show art" do
    game_sessions(:david).update!(status: "finished")
    night = game_sessions(:elias)
    Missionaries::Add.call(night:, name: "Élder Oxxon")
    Missionaries::Add.call(night:, name: "Élder Manning")
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 3.days)
    assert_equal :scheduled, screen.live.state
    assert_equal [ "Élder Oxxon", "Élder Manning" ], screen.live.hosts
    assert_equal "/media/nights/noche_live_stage_v2.png", screen.live.still
    assert_equal screen.backdrop.theme.mode, screen.live.theme_mode
    assert_equal screen.backdrop.theme.atmosphere, screen.live.theme_atmosphere
    refute_equal screen.backdrop.src, screen.live.still
    refute_equal screen.hero.still, screen.live.still
  end

  test "live card resolves an event poster without depending on a view helper" do
    game_sessions(:david).update!(status: "finished")
    night = game_sessions(:elias)
    night.update!(poster_path: "/media/nights/events/benidorm-2026-08-29-reyes-profetas.jpg")

    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 3.days)

    assert_equal night.poster_path, screen.live.still
    assert_equal "light", screen.live.theme_mode
    assert_equal "peaceful", screen.live.theme_atmosphere
  end

  test "dedicated live stage keeps its art and follows a Light hub backdrop" do
    Hubs::Backdrop.entries = [
      {
        "id" => "chapel-worship",
        "image" => "church/worship.jpg",
        "tags" => [ "reyes_y_profetas" ],
        "theme" => { "mode" => "light", "atmosphere" => "peaceful", "accent" => "gold" }
      }
    ]
    game_sessions(:david).update!(status: "finished")
    night = game_sessions(:elias)
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 3.days)
    assert_equal "/media/nights/noche_live_stage_v2.png", screen.live.still
    assert_equal "light", screen.live.theme_mode
    assert_equal "peaceful", screen.live.theme_atmosphere
    refute_equal screen.backdrop.src, screen.live.still
  ensure
    Hubs::Backdrop.reset!
  end

  test "dedicated live stage follows a Dark hub backdrop" do
    Hubs::Backdrop.entries = [
      {
        "id" => "kings-at-night",
        "image" => "quizzes/coronas/ungio_david.jpg",
        "tags" => [ "reyes_y_profetas" ],
        "theme" => { "mode" => "dark", "atmosphere" => "solemn", "accent" => "gold" }
      }
    ]
    game_sessions(:david).update!(status: "finished")
    night = game_sessions(:elias)
    screen = Hubs::Screen.call(device_digest: @digest, ward: @ward, at: night.starts_at - 3.days)

    assert_equal "/media/nights/noche_live_stage_v2.png", screen.live.still
    assert_equal "dark", screen.live.theme_mode
    assert_equal "solemn", screen.live.theme_atmosphere
    refute_equal screen.backdrop.src, screen.live.still
  ensure
    Hubs::Backdrop.reset!
  end

  test "online rows expose real identity rank crowns and count without self" do
    PersonDevice.where(person: people(:carmen_garcia)).update_all(last_seen_at: Time.current)
    PersonDevice.create!(
      person: people(:carmen_lopez),
      device_token: "carmen-lopez-live",
      last_seen_at: Time.current
    )
    Quizzes::StartPack.call(device_digest: "carmen-live", person_id: people(:carmen_garcia).id, pack_id: "coronas")
    QuizRun.create!(
      device_digest: @digest,
      person: @pili,
      pack_id: "coronas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward)
    row = screen.online.find { |item| item.person_id == people(:carmen_garcia).id }
    assert row
    assert_equal 2, screen.online_count
    assert_equal 2, screen.online.size
    refute_includes screen.online.map(&:person_id), @pili.id
    assert_equal people(:carmen_garcia).given_name, row.name
    assert_equal people(:carmen_garcia).avatar_key, row.avatar_key
    assert_equal 5, row.level
    assert_equal 208, row.crowns
    assert_equal QuizDefinition.catalog.find_pack("coronas").copy(:title), row.playing_title
    assert_equal :challenge, row.action
  end

  test "voyage is previous current next and Jouer stays on current pack" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    screen = Hubs::Screen.call(device_digest: @digest)
    assert_equal QuizDefinition.catalog.find_pack("coronas").copy(:title), screen.voyage.previous.title
    assert_equal QuizDefinition.catalog.find_pack("coronas").copy(:kicker), screen.voyage.previous.kicker
    assert_equal "placas", screen.hero.pack_id
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

  test "progress counts unlocked packs and presents four catalog-ordered nodes" do
    screen = Hubs::Screen.call(device_digest: @digest)
    assert_equal 0, screen.progress.finished
    assert_equal 1, screen.progress.unlocked
    assert_equal 1, screen.progress.current_n
    assert_equal screen.hero.title, screen.progress.current_title
    assert screen.progress.total >= 1
    assert_equal 4, screen.progress.nodes.size
    assert_equal %i[current locked locked locked], screen.progress.nodes.map(&:state)
    assert_equal [ true, false, false, false ], screen.progress.nodes.map(&:focus)
    expected = QuizDefinition.catalog.pack_ids.first(4).map do |pack_id|
      QuizDefinition.catalog.find_pack(pack_id).copy(:title)
    end
    assert_equal expected, screen.progress.nodes.map(&:title)
    assert screen.progress.nodes.all? { |node| node.still.present? }
  end

  test "progress window keeps completed current and next packs in source order" do
    pack_ids = QuizDefinition.catalog.pack_ids
    pack_ids.first(3).each_with_index do |pack_id, index|
      QuizRun.create!(
        device_digest: @digest,
        pack_id:,
        position: QuizDefinition::QUESTIONS_PER_PACK,
        score: 40 + index,
        status: "finished",
        opened_at: Time.current
      )
    end

    screen = Hubs::Screen.call(device_digest: @digest)

    assert_equal 3, screen.progress.finished
    assert_equal 4, screen.progress.unlocked
    assert_equal 4, screen.progress.current_n
    assert_equal %i[finished finished current locked], screen.progress.nodes.map(&:state)
    assert_equal pack_ids[1, 4].map { |id| QuizDefinition.catalog.find_pack(id).copy(:title) },
      screen.progress.nodes.map(&:title)
    assert_equal [ false, false, true, false ], screen.progress.nodes.map(&:focus)
  end

  test "open run still counts as the current pack in progress" do
    run = Quizzes::StartPack.call(device_digest: @digest, pack_id: "coronas").run
    screen = Hubs::Screen.call(device_digest: @digest, open_run: run)
    assert_equal 0, screen.progress.finished
    assert_equal 1, screen.progress.current_n
    assert_equal screen.hero.title, screen.progress.current_title
  end

  test "community uses pulse and listed wards" do
    screen = Hubs::Screen.call(device_digest: @digest)
    assert screen.community.wards >= 1
    assert_kind_of Integer, screen.community.players_this_month
    assert_kind_of Integer, screen.community.questions
  end

  test "waiting challenge names the rival and keeps animal keys without inventing scores" do
    duel = StreetDuel.create!(
      challenger_person: @pili,
      opponent_person: people(:carmen_garcia),
      ward: @ward,
      pack_id: "placas",
      token: "hub-screen-wait",
      status: "challenger_done",
      challenger_score: 61,
      expires_at: 7.days.from_now
    )
    challenge = Quizzes::ChallengeScreen.call(person: @pili, duel:)
    screen = Hubs::Screen.call(device_digest: @digest, person: @pili, ward: @ward, challenge:)
    tile = screen.challenge
    refute tile.scored?
    assert_equal :waiting, tile.phase
    assert_equal :accept, tile.waiting_for
    assert_equal "Carmen", tile.other_name
    assert_equal "Carmen García", tile.other_display_name
    assert_equal "tortuga", tile.you_avatar_key
    assert_equal "delfin", tile.other_avatar_key
    assert_nil tile.you_score
    assert_nil tile.other_score
    assert_equal Rails.application.routes.url_helpers.street_challenge_path(duel.token), tile.path
  end

  test "challenge remains renderable while lifecycle methods are not deployed" do
    duel = street_duels(:pili_vs_carmen)
    duel.singleton_class.undef_method(:receipt_state) if duel.respond_to?(:receipt_state)
    duel.singleton_class.undef_method(:rematch?) if duel.respond_to?(:rematch?)
    challenge = Quizzes::ChallengeScreen.call(person: @pili, duel:)

    tile = Hubs::Screen.call(
      device_digest: @digest,
      person: @pili,
      ward: @ward,
      challenge:
    ).challenge

    assert_nil tile.receipt_state
    refute tile.rematch
  end

  test "scored challenge keeps live duel numbers" do
    duel = street_duels(:pili_vs_carmen)
    challenge = Quizzes::ChallengeScreen.call(person: people(:carmen_garcia), duel:)
    screen = Hubs::Screen.call(
      device_digest: @digest,
      person: people(:carmen_garcia),
      ward: @ward,
      challenge:
    )
    tile = screen.challenge
    assert tile.scored?
    assert_equal 90, tile.you_score
    assert_equal 82, tile.other_score
    assert_equal "Pili", tile.other_name
    assert_equal "Pili", tile.other_display_name
    assert_equal "delfin", tile.you_avatar_key
    assert_equal "tortuga", tile.other_avatar_key
  end
end
