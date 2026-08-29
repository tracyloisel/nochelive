require "test_helper"
require "mini_magick"

class ApplicationHelperTest < ActionView::TestCase
  test "responsive picture exposes width candidates and intrinsic dimensions" do
    html = noche_picture(
      "hub.backdrop.moises-mer-rouge",
      role: :hub_backdrop,
      alt: "",
      class_name: "street-world-art",
      loading: "eager",
      fetchpriority: "high"
    )

    assert_includes html, "<picture"
    assert_includes html, "image/avif"
    assert_includes html, "390w"
    assert_includes html, "768w"
    assert_includes html, "941w"
    assert_includes html, "1440w"
    assert_includes html, "1672w"
    assert_includes html, "(min-width: 768px)"
    assert_includes html, 'sizes="100vw"'
    assert_includes html, 'width="941"'
    assert_includes html, 'height="1673"'
    assert_includes html, 'fetchpriority="high"'
  end

  test "compact_number abbreviates large community totals" do
    assert_equal "999", compact_number(999)
    assert_equal "3.5K", compact_number(3_500)
    assert_equal "12K", compact_number(12_000)
    assert_equal "1.3M", compact_number(1_250_000)
    assert_equal "2B", compact_number(2_000_000_000)
  end

  test "challenge media is empty until files exist" do
    night = create_night
    round = night.round_runs.find_by!(yaml_round_id: "scavenger_harp")
    slides = challenge_slides(round)
    if Rails.public_path.join("media/challenges/scavenger_harp/slides").directory?
      assert_includes slides, "/media/challenges/scavenger_harp/slides/01.jpg"
    else
      assert_empty slides
    end
    assert_nil challenge_clip(round)
  end

  test "story art follows the yaml image, not chapel slideshows" do
    round = round_runs(:salomon)
    assert_equal media_src("media/stories/salomon_wisdom_night_portrait.png"), challenge_story(round)
    assert_equal media_src("media/stories/scavenger_harp.jpg"), challenge_story(round_runs(:scavenger_harp))
    assert_equal "stories/salomon_wisdom_night_portrait.png", round.definition.presentation["image"]

    render partial: "shared/challenge_media", locals: { round: round }
    assert_includes rendered, "/media/generated/catalog/stories/salomon_wisdom_night_portrait/"
    assert_not_includes rendered, "slideshow"
    assert_not_includes rendered, "/media/challenges/"
  end

  test "player avatar key cycles through the animal set" do
    night = create_night
    player = add_player(night, name: "Lucía")
    assert_includes Player::AVATARS, player.avatar_key
    expected = "/marks/avatars/#{player.avatar_key}.jpg"
    if Rails.public_path.join("marks/avatars/#{player.avatar_key}.jpg").file?
      assert_equal expected, avatar_mark(player)
    else
      assert_nil avatar_mark(player)
    end
  end

  test "lists slides and clip when files exist" do
    round = round_runs(:scavenger_harp)
    root = Rails.public_path.join("media/challenges/scavenger_harp")
    FileUtils.mkdir_p(root.join("slides"))
    File.write(root.join("slides/01.jpg"), "x")
    File.write(root.join("clip.mp4"), "x")

    assert_includes challenge_slides(round), "/media/challenges/scavenger_harp/slides/01.jpg"
    assert_equal "media/challenges/scavenger_harp/clip.mp4", challenge_clip(round)
  ensure
    FileUtils.rm_rf(Rails.public_path.join("media/challenges/scavenger_harp"))
  end

  test "labels bands medals prompts and roster" do
    I18n.with_locale(:fr) do
      assert_equal "Découverte", band_label(1)
      assert_equal "Commencer la soirée", presenter_next_action(game_sessions(:elias), game_sessions(:elias).current_round_run)[:label]
    end
    I18n.with_locale(:es) do
      assert_equal "Descubrimiento", band_label(1)
    end
    assert_equal "Competencia", band_label(5)
    assert_equal "Fuego", band_label(8)
    assert_equal "Caos", band_label(12)
    assert_equal "Semifinal", band_label(14)
    assert_equal "Gran final", band_label(15)
    assert_equal "1.º", medal_label(1)
    assert_equal "4.º", medal_label(4)
    assert_equal game_sessions(:david).theme_title, night_title(game_sessions(:david))
    assert_equal "La corona se queda en esta casa.", finale_blessing
    assert_includes roster_line(teams(:leones)), "Lucía"
    line = missionary_line(game_sessions(:cerrada))
    assert_includes line, "Élder Soto"
    assert_includes line, "Hermana Clark"
    assert explainer?(teams(:leones), players(:lucia))
    assert player_remote?(players(:daniel))
    assert teams(:daniel_home).solo?
    assert_not teams(:casa).solo?
    assert_nil emblem_mark(nil)
    assert_nil icon_mark("missing")
    assert_match(/Salomón|pidió/i, round_prompt(round_runs(:salomon)).to_s)
    leones = teams(:leones)
    casa = teams(:casa)
    leones.update!(cached_score: 40)
    casa.update!(cached_score: 12)
    assert_equal "Leones de Judá va delante.", night_leader_line(game_sessions(:david))
    casa.update!(cached_score: 40)
    assert_equal "Casa de David y Leones de Judá van juntos.", night_leader_line(game_sessions(:david))
    Ballot.delete_all
    Ballot.create!(round_run: round_runs(:vote_solomon), team: leones, player: players(:lucia), choice_team: casa)
    assert_equal "¡Casa de David tiene la sabiduría!", vote_tally_line(round_runs(:vote_solomon))
    leones.pending_rank_up = "Explorador"
    leones.next_correct_doubled = false
    assert_equal "¡Leones de Judá es Explorador!", rank_up_shout(leones)
    leones.next_correct_doubled = true
    assert_equal "¡Leones de Judá es Explorador y Rey!", rank_up_shout(leones)
  end

  test "intro sfx yields to an open pulse" do
    round = round_runs(:lobby_first)
    round.intro!
    assert_equal "round_start", stage_sfx(round)
    assert_nil stage_sfx(round, pulse: { kind: "open" })
    assert_nil stage_sfx(round, pulse: { kind: "advance" })
    assert_equal "round_start", stage_sfx(round, pulse: { kind: "buzz" })
  end

  test "stage sfx and fx follow round and night" do
    round = round_runs(:salomon)
    round.update_column(:opened_at, Time.current)
    assert_nil stage_sfx(round)
    assert_equal "timer_tension", stage_bed(round, night: game_sessions(:david))
    assert_includes stage_sfx_token(round, nil, night: game_sessions(:david)), "open"
    round.update!(phase: "revealed")
    assert_nil stage_sfx(round.reload)
    assert_nil stage_bed(round, night: game_sessions(:david))
    assert_equal "reveal", stage_fx(round)
    pending = teams(:leones)
    pending.pending_rank_up = "Explorador"
    pending.next_correct_doubled = true
    assert_equal "¡Leones de Judá es Explorador y Rey!", rank_up_shout(pending)
    assert_equal "level_up", stage_sfx(nil, team: pending)
    assert_equal "royal_fanfare", stage_sfx(nil, night: game_sessions(:cerrada))
    assert_equal "finale", stage_fx(nil, night: game_sessions(:cerrada))
    assert_equal "custom", stage_sfx(round, "custom")
    assert_equal "fx", stage_fx(round, "fx")

    freeze = round_runs(:freeze_saul)
    freeze.update!(phase: "locked")
    assert_nil stage_sfx(freeze)
    assert_equal "shake", stage_fx(freeze)
  end

  test "burger stakes follow the board for two and three teams" do
    night = game_sessions(:david)
    leones = teams(:leones)
    casa = teams(:casa)
    leones.update!(cached_score: 40)
    casa.update!(cached_score: 10)
    assert_equal "El burger puede cambiar el marcador.", burger_stakes_line(night)
    assert_equal "Si acertáis, pasáis delante.", burger_stakes_line(night, casa)
    assert_equal "Podéis cerrar la noche.", burger_stakes_line(night, leones)
    casa.update!(cached_score: 40)
    assert_equal "Van juntos. El burger deshace el empate.", burger_stakes_line(night, leones)

    third = night.teams.create!(name: "Olas", emblem: "ola")
    leones.update!(cached_score: 50)
    casa.update!(cached_score: 50)
    third.update!(cached_score: 10)
    assert_equal "Van juntos. El burger deshace el empate.", burger_stakes_line(night, leones)
    assert_equal "Si acertáis, pasáis delante.", burger_stakes_line(night, third)
  end

  test "burger clip and garnish follow the layer" do
    round = round_runs(:finale_prophet)
    round.update!(phase: "intro", layer_index: 0)
    assert_equal media_src("media/burger/chariot.jpg"), challenge_story(round)
    assert_equal "media/burger/chariot.mp4", burger_clip(round)
    assert_equal "fry", burger_garnish_kind(round)

    round.update!(layer_index: 2)
    assert_equal media_src("media/burger/jordan.jpg"), challenge_story(round)
    assert_equal "media/burger/jordan.mp4", burger_clip(round)
    assert_equal "lettuce", burger_garnish_kind(round)
    assert_equal 24, burger_garnish_count(round, cinema: true)

    render partial: "shared/challenge_media", locals: { round: round, cinema: true }
    assert_includes rendered, "challenge-clip"
    assert_includes rendered, "data-garnish-kind-value=\"lettuce\""
  end

  test "pictos and choice marks stay visual" do
    svg = picto("door")
    assert_includes svg, "picto-door"
    assert_includes picto("close"), "picto-close"
    assert_includes picto("wave"), "picto-wave"
    assert_includes picto("fish"), "picto-fish"
    assert_includes picto("tick"), "picto-tick"
    assert_includes picto("cross"), "picto-cross"
    assert_includes picto("close"), "picto-close"
    assert_includes svg, "<svg"
    assert_includes picto("fire"), "picto-fire"
    assert_includes picto("crown"), "picto-crown"
    assert_includes picto("scroll"), "picto-scroll"
    assert_includes picto("scripture-book"), "picto-scripture-book"
    assert_includes picto("arrow"), "picto-arrow"
    assert_includes picto("whatsapp"), "picto-whatsapp"
    assert_includes picto("share"), "picto-share"
    assert_includes picto("copy"), "picto-copy"
    assert_includes picto("instagram"), "picto-instagram"
    menu = picto("menu")
    assert_includes menu, "picto-menu"
    assert_includes menu, "currentColor"
    refute_includes menu, 'stroke="#1a2744"'
    person = picto("person")
    assert_includes person, "picto-person"
    assert_includes person, "currentColor"
    refute_includes person, 'fill="#d4a017"'
    assert_equal "circle", choice_mark(0)[:shape]
    assert_equal "gold", choice_mark(0)[:tone]
    assert_equal "star", choice_mark(3)[:shape]
    assert_equal "gold", choice_mark(4)[:tone]
    assert_equal "true", choice_key({ "key" => "true", "label" => "Verdadero" })
    assert_equal "Verdadero", choice_label({ "key" => "true", "label" => "Verdadero" })
    assert_equal "fire", choice_label("fire")
  end

  test "answer_body_label uses Spanish choice labels" do
    round = round_runs(:rey_o_profeta)
    answer = Answer.new(body: "false", round_run: round, team: teams(:leones), player: players(:lucia))
    assert_equal "Falso", answer_body_label(round, answer)
    assert_equal "Sabiduría", answer_body_label(round_runs(:salomon), Answer.new(body: "wisdom"))
  end

  test "player_label adds apellido when two share a name" do
    night = game_sessions(:david)
    carmen = add_player(night, name: "Carmen")
    carmen.update!(person: people(:carmen_garcia), name: "Carmen")
    add_player(night, name: "Carmen")
    assert_equal "Carmen García", player_label(carmen.reload)
    assert_equal "/marks/avatars/delfin.jpg", avatar_mark("delfin")
  end

  test "latency_label prints milliseconds" do
    assert_equal "342 ms", latency_label(342)
    assert_nil latency_label(nil)
  end

  test "ceremony shows temporada rise for the whole room" do
    teams(:leones).update!(season_rank_up: "Explorador")
    render partial: "shared/ceremony", locals: { night: game_sessions(:david) }
    assert_includes rendered, "Temporada"
    assert_includes rendered, "Leones de Judá"
    assert_includes rendered, "Explorador"
  end

  test "empty ceremony does not shout a coronation" do
    night = game_sessions(:elias)
    render partial: "shared/ceremony", locals: { night: night }
    assert_includes rendered, "La noche cierra."
    assert_not_includes rendered, "¡TODOS DE PIE!"
    assert_not_includes rendered, "Gran final"
  end

  test "ceremony still prefers a round painting over the flyer" do
    src = ceremony_still_src(game_sessions(:david))
    assert src.present?
    assert_not_equal night_poster_src(game_sessions(:david)), src
    assert_not_includes src, "/media/nights/"
  end

  test "street_xp_cap is the next rank threshold" do
    assert_equal 25, street_xp_cap(0)
    assert_equal 60, street_xp_cap(25)
    assert_nil street_xp_cap(260)
  end

  test "street_xp_remaining is points still needed for the next rank" do
    assert_equal 25, street_xp_remaining(0)
    assert_equal 20, street_xp_remaining(40)
    assert_equal 15, street_xp_remaining(95)
    assert_nil street_xp_remaining(260)
  end

  test "player card puts rank progress in ink beside the gold fill" do
    standings = Struct.new(:total_score, :rank_title).new(40, "Explorador")
    streak = Struct.new(:days).new(1)
    render partial: "street_hub/player_card", locals: {
      person: people(:pili),
      standings:,
      streak:
    }

    assert_includes rendered, I18n.t("street.card_xp_left", count: 20, rank: I18n.t("ranks.guerrero"))
    assert_not_includes rendered, "40 / 60"
    assert_select ".street-xp-bar .street-xp-fill"
    assert_select ".street-xp-caption", text: I18n.t("street.card_xp_left", count: 20, rank: I18n.t("ranks.guerrero"))
    assert_select ".street-xp-bar .street-xp-caption", count: 0
  end

  test "player card at the last rank names the summit" do
    standings = Struct.new(:total_score, :rank_title).new(260, "Leyenda")
    streak = Struct.new(:days).new(3)
    render partial: "street_hub/player_card", locals: {
      person: people(:pili),
      standings:,
      streak:
    }

    assert_select ".street-xp-caption", text: I18n.t("street.card_xp_max", rank: I18n.t("ranks.leyenda"))
    assert_select ".street-rank-banner", text: I18n.t("ranks.leyenda")
  end

  test "temple_hall_bg_src prefers OpenRouter hall photo when present" do
    assert_equal media_src("media/temple/marble-hall.jpg"), temple_hall_bg_src
  end

  test "street_ceremony_asset_src finds temple PNGs" do
    %w[reward-chest ceremony-chest marble-hall-victory ceremony-gateway].each do |name|
      assert_match %r{\A/media/generated/catalog/temple/#{name}/.+\.webp\z}, street_ceremony_asset_src(name)
    end
    assert_nil street_ceremony_asset_src("missing-ornament")
  end

  test "hub reward chest is a genuinely transparent PNG" do
    image = MiniMagick::Image.open(Rails.root.join("media/masters/media/temple/reward-chest.png"))

    assert_match(/a/, image["%[channels]"])
    assert_equal "false", image["%[opaque]"].downcase
    assert_match(/,0\)\z/, image["%[pixel:p{0,0}]"])
  end

  test "street_clock formats total seconds" do
    assert_equal "00:00", street_clock(0)
    assert_equal "04:32", street_clock(272)
    assert_equal "00:00", street_clock(-3)
  end

  test "scripture read counts use native thousands separators and plurals" do
    expected = { es: "1.284 lecturas", en: "1,284 reads", fr: "1 284 lectures", "pt-BR": "1.284 leituras" }

    expected.each do |locale, label|
      I18n.with_locale(locale) { assert_equal label, scripture_read_count_label(1_284) }
    end
    I18n.with_locale(:fr) { assert_equal "1 lecture", scripture_read_count_label(1) }
  end

  test "ceremony_board_rows keeps three then you if you sit off the podium" do
    row = ->(rank, you, context) {
      Quizzes::Leaderboard::Row.new(rank:, person: people(:pili), score: 80, you:, context:)
    }
    board = Quizzes::Leaderboard::Board.new(
      rows: [ row.call(1, false, nil), row.call(2, false, nil), row.call(3, false, nil), row.call(8, true, :you) ]
    )
    names = ceremony_board_rows(board)
    assert_equal 4, names.size
    assert names.last.you
    assert_equal :you, names.last.context
  end

  test "street ceremony verdict names the duel consequence" do
    complete = Struct.new(:score, :answered, :correct).new(76, 10, 8)
    impact = Struct.new(:outcome, :other, :mine, :theirs).new(:behind, people(:pili), 76, 91)

    I18n.with_locale(:fr) do
      verdict = street_ceremony_verdict(complete:, impacts: [ impact ])
      assert_equal :behind, verdict[:tone]
      assert_equal "#{people(:pili).given_name} garde l’avantage", verdict[:title]
      assert_equal "Ton score : 76 couronnes. Écart à combler : 15 couronnes.", verdict[:detail]
    end
  end

  test "street ceremony verdict describes performance when no duel changed" do
    complete = Struct.new(:score, :answered, :correct).new(124, 10, 10)

    I18n.with_locale(:fr) do
      verdict = street_ceremony_verdict(complete:, impacts: [])
      assert_equal :perfect, verdict[:tone]
      assert_equal "Sans faute !", verdict[:title]
      assert_equal "Réponses justes : 10/10 · 124 couronnes", verdict[:detail]
    end
  end

  test "presenter next action is a single sequential verb" do
    night = game_sessions(:david)
    round = round_runs(:salomon)
    round.update_column(:opened_at, Time.current)
    action = presenter_next_action(night, round)
    assert_equal "Cerrar buzzer", action[:label]

    lobby = game_sessions(:elias)
    assert_equal "Empezar la noche", presenter_next_action(lobby, lobby.current_round_run)[:label]
  end

  test "church stills resolve when the painting exists" do
    assert_nil church_still_src("missing_door")
    path = Rails.public_path.join("media/church/_spec.jpg")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, "x")
    assert_equal "/media/church/_spec.jpg", church_still_src("_spec")
  ensure
    FileUtils.rm_f(path) if path
  end

  test "about portrait is the circular tracy still" do
    assert_equal media_src("media/about/tracy.png"), about_portrait_src
  end

  test "about reach links open WhatsApp and Instagram" do
    assert_equal "https://wa.me/34689226754", about_whatsapp_url
    assert_equal "https://www.instagram.com/tracy_loisel/", about_instagram_url
  end

  test "night poster and status captions" do
    assert_equal media_src("media/nights/reyes_y_profetas.jpg"), night_poster_src(game_sessions(:david))
    assert_equal media_src("media/nights/reyes_y_profetas.jpg"), night_poster_src("reyes_y_profetas")
    assert_equal media_src("media/stories/salomon_wisdom_night_portrait.png"), night_still_src(game_sessions(:david))
    assert_equal media_src("media/nights/reyes_y_profetas.jpg"), night_still_src(nil)
    assert_equal "En juego", night_status_caption(game_sessions(:david))
    assert_equal "En el vestíbulo", night_status_caption(game_sessions(:elias))
    assert_equal "Terminada", night_status_caption(game_sessions(:cerrada))
    paused = game_sessions(:david)
    paused.status = "paused"
    assert_equal "En pausa", night_status_caption(paused)
    assert_nil night_poster_src("missing_theme")
  end

  test "a session event poster takes priority over its theme poster" do
    night = game_sessions(:elias)
    night.poster_path = "/media/nights/events/benidorm-2026-08-29-reyes-profetas.jpg"

    assert_equal media_src(night.poster_path), night_poster_src(night)
  end

  test "home night path is the memory for a finished night" do
    assert_equal night_name_path("DAVID"), home_night_path_for(game_sessions(:david))
    assert_equal ward_memory_path("RAMA", "QUIT"), home_night_path_for(game_sessions(:cerrada))
  end

  test "phone quiz is the QCM for choice rounds and for casa on a buzzer" do
    assert phone_quiz?(round_runs(:rey_o_profeta), players(:lucia))
    assert phone_quiz?(round_runs(:salomon), players(:daniel))
    assert_not phone_quiz?(round_runs(:salomon), players(:lucia))
    assert phone_quiz_asking?(round_runs(:salomon), players(:daniel))
    assert_not phone_quiz_asking?(round_runs(:salomon), players(:lucia))
  end

  test "street praise is stable per run and question" do
    digest = GameSession.digest_token("helper-praise")
    frame = Quizzes::Draw.call(device_digest: digest)
    run = frame.run
    first = street_praise_line(run, frame.question)
    assert_equal first, street_praise_line(run, frame.question)
    assert_includes I18n.t("street.praises"), first

    shouts = (1..QuizDefinition::QUESTIONS_PER_PACK).map do |position|
      street_praise_line(run, run.pack.question_at(position))
    end
    assert_operator shouts.uniq.size, :>=, 2

    I18n.with_locale(:fr) do
      french = street_praise_line(run, frame.question)
      assert_includes I18n.t("street.praises"), french
      assert_not_equal first, french
    end
  end

  test "street hit shout replaces praise on a streak milestone" do
    digest = GameSession.digest_token("helper-hit-shout")
    frame = Quizzes::Draw.call(device_digest: digest)
    run = frame.run
    quiet = Struct.new(:shout_key).new(nil)
    assert_equal street_praise_line(run, frame.question), street_hit_shout(run, frame.question, quiet)
    assert_equal I18n.t("quiz.streak_two"), street_hit_shout(run, frame.question, Struct.new(:shout_key).new("two"))
    I18n.with_locale(:fr) do
      assert_equal I18n.t("quiz.streak_ten"), street_hit_shout(run, frame.question, Struct.new(:shout_key).new("ten"))
    end
  end

  test "street choices shuffle per run question" do
    digest = GameSession.digest_token("helper-shuffle")
    frame = Quizzes::Draw.call(device_digest: digest)
    yaml_first = frame.question.correct_choice
    moved = (1..50).any? do |offset|
      seed = frame.run.id.to_i * 1_000 + frame.question.position.to_i + offset
      shown_first = choice_key(frame.question.shuffled_choices(seed).first)
      shown_first != yaml_first
    end
    assert moved
  end

  test "street audio uses one named cue and keeps the overlay bed between questions" do
    digest = GameSession.digest_token("helper-street")
    frame = Quizzes::Draw.call(device_digest: digest)
    ask = street_audio_data(frame.run, frame.question)
    assert_equal "celestial_breath", ask[:stage_sfx_value]
    assert_nil ask[:stage_bed_value]
    assert_match(/:ask\z/, ask[:stage_sfx_token_value])

    manual = street_audio_data(frame.run, frame.question, manual: true)
    assert_equal "manual", manual[:stage_cue_policy_value]
    assert_nil manual[:stage_fx_value]

    continuous = street_audio_data(frame.run, frame.question, manual: true, ask_bed: "timer_tension")
    assert_equal "timer_tension", continuous[:stage_bed_value]
    assert_equal "continuous", continuous[:stage_bed_policy_value]
    assert_nil continuous[:stage_timer_end_value]
    assert_nil continuous[:stage_timer_duration_value]

    Quizzes::Submit.call(run: frame.run, choice_key: frame.question.correct_choice)
    settled = street_audio_data(frame.run.reload, frame.question)
    assert_equal "correct_gold", settled[:stage_sfx_value]
    assert_nil settled[:stage_fx_value]
    assert_nil settled[:stage_bed_value]
    assert_match(/:settled:correct\z/, settled[:stage_sfx_token_value])

    continuous_settled = street_audio_data(frame.run.reload, frame.question, manual: true, ask_bed: "timer_tension")
    assert_equal "timer_tension", continuous_settled[:stage_bed_value]
    assert_equal "continuous", continuous_settled[:stage_bed_policy_value]
    assert_nil continuous_settled[:stage_timer_end_value]
  end

  test "timed street settle clears the tension bed and tick timer" do
    digest = GameSession.digest_token("helper-timed-settle")
    run = Quizzes::Draw.call(device_digest: digest).run
    run.update!(position: 4, ends_at: 20.seconds.from_now)
    ask = street_audio_data(run, run.question)
    assert_nil ask[:stage_sfx_value]
    assert_equal "timer_tension", ask[:stage_bed_value]
    assert ask[:stage_timer_end_value].present?

    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    settled = street_audio_data(run.reload, run.question)
    assert_equal "correct_gold", settled[:stage_sfx_value]
    assert_nil settled[:stage_bed_value]
    assert_nil settled[:stage_timer_end_value]
    assert_nil settled[:stage_timer_duration_value]
  end

  test "street miss uses its isolated quiet cue" do
    digest = GameSession.digest_token("helper-street-miss")
    run = Quizzes::Draw.call(device_digest: digest).run
    wrong_choice = run.question.choices.find { |choice| choice_key(choice) != run.question.correct_choice }

    Quizzes::Submit.call(run:, choice_key: choice_key(wrong_choice))

    settled = street_audio_data(run.reload, run.question)
    assert_equal "street_wrong_soft", settled[:stage_sfx_value]
    assert_nil settled[:stage_bed_value]
  end

  test "street streak break keeps the miss cue gentle" do
    digest = GameSession.digest_token("helper-street-streak-break")
    run = Quizzes::Draw.call(device_digest: digest).run
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Advance.call(run: run.reload)
    run.reload
    wrong_choice = run.question.choices.find { |choice| choice_key(choice) != run.question.correct_choice }
    Quizzes::Submit.call(run:, choice_key: choice_key(wrong_choice))
    combo = Quizzes::HitStreak.call(run: run.reload)

    settled = street_audio_data(run, run.question, manual: true, combo:)

    assert combo.broke
    assert_equal 1, combo.broken_count
    assert_equal "street_wrong_soft", settled[:stage_sfx_value]
    assert_nil settled[:stage_bed_value]
  end

  test "street slam ask uses round_start and pack done uses its isolated fanfare" do
    digest = GameSession.digest_token("helper-slam")
    run = Quizzes::Draw.call(device_digest: digest).run
    run.update!(position: 10, ends_at: 15.seconds.from_now)
    slam = street_audio_data(run, run.question)
    assert_nil slam[:stage_sfx_value]
    assert_equal "timer_tension", slam[:stage_bed_value]
    assert slam[:stage_timer_end_value].present?
    assert_equal 15, slam[:stage_timer_duration_value]

    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    done = street_audio_data(run.reload, run.question)
    assert_equal "street_royal_fanfare", done[:stage_sfx_value]
    assert_equal "level", done[:stage_fx_value]
    assert_nil done[:stage_bed_value]
  end

  test "ask timer zones follow remaining percent of duration" do
    assert play_timer_warn?(4, 10)
    assert play_timer_hot?(2, 10)
    refute play_timer_warn?(5, 10)
    refute play_timer_hot?(3, 10)

    refute play_timer_warn?(15, 15)
    refute play_timer_hot?(15, 15)
    assert play_timer_warn?(6, 15)
    refute play_timer_hot?(6, 15)
    assert play_timer_hot?(3, 15)

    refute play_timer_warn?(20, 20)
    assert play_timer_warn?(8, 20)
    assert play_timer_hot?(4, 20)

    refute play_timer_warn?(1, 0)
    refute play_timer_hot?(1, 0)
    refute play_timer_warn?(0, 15)
  end

  test "street play keeps mute and language in the hamburger" do
    content_for(:body_class, "is-kid is-street-play")
    assert chrome_tools_in_drawer?
    assert chrome_face?
  end

  test "church videos keeps mute and language in the hamburger" do
    content_for(:body_class, "is-kid is-church-videos")
    assert chrome_tools_in_drawer?
    assert chrome_face?
  end

  test "live night play keeps mute beside the cream head" do
    content_for(:body_class, "is-kid is-play")
    assert_not chrome_tools_in_drawer?
    assert_not chrome_face?
  end

  test "fresh 15s ask timer markup is not warn or low" do
    digest = GameSession.digest_token("helper-timer-paint")
    run = Quizzes::Draw.call(device_digest: digest).run
    run.update!(position: 10, ends_at: 15.seconds.from_now)
    render partial: "play/timer", locals: { round: run }
    assert_includes rendered, "data-countdown-ask-value=\"true\""
    assert_not_includes rendered, "is-warn"
    assert_not_includes rendered, "is-low"
  end

  test "ward street is the chapel address when present" do
    assert_equal "Avinguda Alfonso Puchades, 27", ward_street(wards(:demo))
    assert_nil ward_street(wards(:blank))
    assert_equal "Calle del Prado 1", ward_street(Wards::Search::Hit.new(chapel_address: "Calle del Prado 1"))
  end

  test "hub_live_when uses weekday plus time past 48 hours" do
    starts = Time.zone.parse("2026-08-29 19:00")
    live = Hubs::Screen::Live.new(state: :scheduled, starts_at: starts)
    copy = hub_live_when(live, now: starts - 3.days)
    assert_includes copy, "19:00"
    refute_match(/\d{2}:\d{2}:\d{2}/, copy)
  end

  test "hub_live_when keeps weekday when the clock is also on" do
    starts = Time.zone.parse("2026-08-27 19:00")
    live = Hubs::Screen::Live.new(state: :imminent, starts_at: starts)
    copy = hub_live_when(live, now: starts - 8.hours)
    assert_includes copy, "19:00"
  end

  test "hub_live_when speaks 19h in French" do
    starts = Time.zone.parse("2026-08-29 19:00")
    live = Hubs::Screen::Live.new(state: :scheduled, starts_at: starts)
    I18n.with_locale(:fr) do
      copy = hub_live_when(live, now: starts - 3.days)
      assert_match(/samedi 19h/i, copy)
      refute_includes copy, "19:00"
    end
  end
end
