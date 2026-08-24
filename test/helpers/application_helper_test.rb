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
    assert_equal "Descubrimiento", band_label(1)
    assert_equal "Competencia", band_label(5)
    assert_equal "Fuego", band_label(8)
    assert_equal "Caos", band_label(12)
    assert_equal "Semifinal", band_label(14)
    assert_equal "Gran final", band_label(15)
    assert_equal "1.º", medal_label(1)
    assert_equal "4.º", medal_label(4)
    assert_equal "illustrations/crown", illustration_partial(nil)
    assert_equal "illustrations/harp", illustration_partial("harp")
    assert_equal game_sessions(:david).theme_title, night_title(game_sessions(:david))
    assert_equal "La corona se queda en esta casa.", finale_blessing
    assert_includes roster_line(teams(:leones)), "Lucía"
    line = missionary_line(game_sessions(:cerrada))
    assert_includes line, "Élder Soto"
    assert_includes line, "Hermana Clark"
    assert explainer?(teams(:leones), players(:lucia))
    assert player_remote?(players(:daniel))
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
    assert_equal "round_start", stage_sfx(round)
    round.update!(phase: "revealed")
    assert_equal "correct_gold", stage_sfx(round.reload)
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
    assert_equal "dramatic_fire", stage_sfx(freeze)
    assert_equal "shake", stage_fx(freeze)
  end

  test "pictos and choice marks are picture-first" do
    svg = picto("door")
    assert_includes svg, "picto-door"
    assert_includes picto("close"), "picto-close"
    assert_includes picto("wave"), "picto-wave"
    assert_includes picto("fish"), "picto-fish"
    assert_includes picto("tick"), "picto-tick"
    assert_includes picto("cross"), "picto-cross"
    assert_includes picto("close"), "picto-close"
    assert_includes svg, "<svg"
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
    assert_equal "Sabiduría", answer_body_label(round_runs(:salomon), answers(:leones_lions))
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

  test "night poster and status captions" do
    assert_equal "/media/nights/reyes_y_profetas.jpg", night_poster_src(game_sessions(:david))
    assert_equal "/media/nights/reyes_y_profetas.jpg", night_poster_src("reyes_y_profetas")
    assert_equal "En juego", night_status_caption(game_sessions(:david))
    assert_equal "En el vestíbulo", night_status_caption(game_sessions(:elias))
    assert_equal "Terminada", night_status_caption(game_sessions(:cerrada))
    paused = game_sessions(:david)
    paused.status = "paused"
    assert_equal "En pausa", night_status_caption(paused)
    assert_nil night_poster_src("missing_theme")
  end
end
