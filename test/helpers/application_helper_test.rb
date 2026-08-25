require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
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
    assert_equal "/media/stories/salomon_wisdom.jpg", challenge_story(round)
    assert_equal "/media/stories/scavenger_harp.jpg", challenge_story(round_runs(:scavenger_harp))
    assert_equal "stories/salomon_wisdom.jpg", round.definition.presentation["image"]

    render partial: "shared/challenge_media", locals: { round: round }
    assert_includes rendered, "/media/stories/salomon_wisdom.jpg"
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

  test "intro sfx" do
    round = round_runs(:lobby_first)
    round.intro!
    assert_equal "round_start", stage_sfx(round)
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
    assert_equal "/media/burger/chariot.jpg", challenge_story(round)
    assert_equal "media/burger/chariot.mp4", burger_clip(round)
    assert_equal "fry", burger_garnish_kind(round)

    round.update!(layer_index: 2)
    assert_equal "/media/burger/jordan.jpg", challenge_story(round)
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
    assert_includes picto("arrow"), "picto-arrow"
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

  test "presenter next action is a single sequential verb" do
    night = game_sessions(:david)
    round = round_runs(:salomon)
    round.update_column(:opened_at, Time.current)
    action = presenter_next_action(night, round)
    assert_equal "Cerrar buzzer", action[:label]

    lobby = game_sessions(:elias)
    assert_equal "Empezar la noche", presenter_next_action(lobby, lobby.current_round_run)[:label]
  end

  test "night poster and status captions" do
    assert_equal "/media/nights/reyes_y_profetas.jpg", night_poster_src(game_sessions(:david))
    assert_equal "/media/nights/reyes_y_profetas.jpg", night_poster_src("reyes_y_profetas")
    assert_equal "/media/stories/salomon_wisdom.jpg", night_still_src(game_sessions(:david))
    assert_equal "/media/nights/reyes_y_profetas.jpg", night_still_src(nil)
    assert_equal "En juego", night_status_caption(game_sessions(:david))
    assert_equal "En el vestíbulo", night_status_caption(game_sessions(:elias))
    assert_equal "Terminada", night_status_caption(game_sessions(:cerrada))
    paused = game_sessions(:david)
    paused.status = "paused"
    assert_equal "En pausa", night_status_caption(paused)
    assert_nil night_poster_src("missing_theme")
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

  test "street choices shuffle per run question" do
    digest = GameSession.digest_token("helper-shuffle")
    frame = Quizzes::Draw.call(device_digest: digest)
    yaml_first = frame.question.correct_choice
    shown_first = choice_key(street_shuffled_choices(frame.run, frame.question).first)
    assert_not_equal yaml_first, shown_first
  end

  test "street audio uses one named cue and stops the bed when settled" do
    digest = GameSession.digest_token("helper-street")
    frame = Quizzes::Draw.call(device_digest: digest)
    ask = street_audio_data(frame.run, frame.question)
    assert_equal "question_change", ask[:stage_sfx_value]
    assert_nil ask[:stage_bed_value]
    assert_match(/:ask\z/, ask[:stage_sfx_token_value])

    Quizzes::Submit.call(run: frame.run, choice_key: frame.question.correct_choice)
    settled = street_audio_data(frame.run.reload, frame.question)
    assert_equal "correct_gold", settled[:stage_sfx_value]
    assert_equal "gold", settled[:stage_fx_value]
    assert_nil settled[:stage_bed_value]
    assert_match(/:settled:correct\z/, settled[:stage_sfx_token_value])
  end

  test "street slam ask uses round_start and pack done uses royal_fanfare" do
    digest = GameSession.digest_token("helper-slam")
    run = Quizzes::Draw.call(device_digest: digest).run
    run.update!(position: 10, ends_at: 15.seconds.from_now)
    slam = street_audio_data(run, run.question)
    assert_equal "round_start", slam[:stage_sfx_value]
    assert_equal "timer_tension", slam[:stage_bed_value]
    assert slam[:stage_timer_end_value].present?
    assert_equal 15, slam[:stage_timer_duration_value]

    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    done = street_audio_data(run.reload, run.question)
    assert_equal "royal_fanfare", done[:stage_sfx_value]
    assert_equal "level", done[:stage_fx_value]
    assert_nil done[:stage_bed_value]
  end
end
