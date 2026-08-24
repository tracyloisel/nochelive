require "test_helper"

class NightFlowTest < ActionDispatch::IntegrationTest
  test "player joins by code case-insensitively and refresh does not clone" do
    night = create_night
    post join_path, params: { code: night.code.downcase }
    assert_redirected_to night_name_path(night.code)

    get night_name_path(night.code)
    assert_response :success
    assert_select "h1", text: /llama/

    post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    assert_equal 1, night.players.count

    get night_name_path(night.code)
    assert_redirected_to night_play_path(night.code)
    assert_equal 1, night.players.count
  end

  test "spectator cannot open a buzzer" do
    night = create_night
    post join_path, params: { code: night.code, as: "watch" }
    follow_redirect!
    get night_watch_path(night.code)
    assert_response :success
    assert_select ".live"
    assert_select "form[action*='buzz']", count: 0
  end

  test "presenter token is required and scores move after a buzz" do
    night = create_night
    token = SecureRandom.urlsafe_base64(24)
    night.update!(presenter_token_digest: GameSession.digest_token(token), presenter_token: token)

    get presenter_console_path(night.code)
    assert_redirected_to presenter_gate_path(night.code)

    get presenter_gate_path(night.code, token: token)
    assert_redirected_to presenter_console_path(night.code)
    get presenter_console_path(night.code)
    assert_response :success

    team = add_team(night, name: "Leones")
    player = add_player(night, name: "Carlos", team: team)
    post presenter_start_path(night.code)
    round = night.reload.current_round_run
    post presenter_open_round_path(night.code, round)

    cookies[:noche_player] = player.id
    # Use a dedicated player session for the buzz
    open_session do |player_sess|
      player_sess.post night_players_path(night.code), params: { name: "Ana", location: "remote" }
      player_sess.post night_teams_path(night.code), params: { name: "Profetas", emblem: "fuego" }
      player_sess.post presenter_open_round_path(night.code, night.reload.current_round_run)
    end

    get presenter_console_path(night.code)
    assert_select ".code-chip", text: night.code
  end

  test "buzzer flow awards first place to one team" do
    night = create_night
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token))

    get presenter_gate_path(night.code, token: token)
    post presenter_start_path(night.code)
    round = night.reload.current_round_run
    post presenter_open_round_path(night.code, round)
    assert_equal "open", round.reload.phase

    player_one = open_session
    player_one.post night_players_path(night.code), params: { name: "Marta", location: "room" }
    player_one.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }

    player_two = open_session
    player_two.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    player_two.post night_teams_path(night.code), params: { name: "Profetas", emblem: "fuego" }

    round = night.reload.current_round_run
    player_one.post night_round_run_buzz_path(night.code, round)
    player_two.post night_round_run_buzz_path(night.code, round)

    positions = Buzz.where(round_run: round).order(:position).pluck(:position)
    assert_equal [ 1, 2 ], positions
    assert_equal 2, Buzz.where(round_run: round).select(:team_id).distinct.count

    player_one.get night_play_path(night.code)
    assert_includes player_one.response.body, "1.º"

    player_two.get night_play_path(night.code)
    assert_includes player_two.response.body, "2.º"

    get night_watch_path(night.code)
    assert_includes response.body, "Leones"
  end

  test "rank up becomes a playable event" do
    night = create_night
    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Marta", location: "room" }
    remote.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    team = night.teams.find_by!(name: "Leones")
    ScoreEvent.award!(game_session: night, team: team, kind: "adjust", points: 0, xp: 30, reason: "prueba")
    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "Explorador"
    assert_includes remote.response.body, "Nueva dignidad"
    assert_includes remote.response.body, "Sois Rey"
    assert_includes remote.response.body, "doble"
    remote.post night_rank_up_path(night.code)
    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "Rey · próxima"
    get night_watch_path(night.code)
    assert_includes response.body, "es Rey esta ronda"
  end

  test "statue is a body verb in the room and a hold at home" do
    night = create_night
    statue = night.round_runs.find_by!(yaml_round_id: "statue_david")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    statue.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, statue)

    room = open_session
    room.post night_players_path(night.code), params: { name: "María", location: "room" }
    room.post night_teams_path(night.code), params: { name: "Sala", emblem: "leon" }
    room.get night_play_path(night.code)
    assert_includes room.response.body, "DEJAD EL TELÉFONO"

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "Sostener"
    assert_not_includes remote.response.body, "DEJAD EL TELÉFONO"
  end

  test "remote jonah lives the story instead of guessing the room" do
    night = create_night
    mime = night.round_runs.find_by!(yaml_round_id: "mime_jonah")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    mime.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, mime)

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "TÚ ERES JONÁS"
    assert_includes remote.response.body, "¡LA TORMENTA!"
    assert_includes remote.response.body, "¡EL PEZ!"
    assert_includes remote.response.body, "¡TIERRA!"
    remote.assert_select ".play-stage", text: /TÚ ERES JONÁS/
    remote.assert_select ".play-stage", text: /Daniel y los leones/, count: 0

    get night_watch_path(night.code)
    assert_includes response.body, "SIN PALABRAS"
    assert_not_includes response.body, "¡LA TORMENTA!"
  end

  test "taboo splits explainer and guesser and remote can type a guess" do
    night = create_night
    taboo = night.round_runs.find_by!(yaml_round_id: "taboo_nabot")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    taboo.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, taboo)

    explainer = open_session
    explainer.post night_players_path(night.code), params: { name: "Marta", location: "room" }
    explainer.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    team = night.teams.find_by!(name: "Leones")

    room_guesser = open_session
    room_guesser.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    room_guesser.post night_team_memberships_path(night.code, team)

    guesser = open_session
    guesser.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    guesser.post night_team_memberships_path(night.code, team)

    miss = open_session
    miss.post night_players_path(night.code), params: { name: "Ana", location: "remote" }
    miss.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    casa = night.teams.find_by!(name: "Casa")

    explainer.get night_play_path(night.code)
    assert_includes explainer.response.body, "TÚ EXPLICAS"
    assert_includes explainer.response.body, "Acab"
    assert_includes explainer.response.body, "La viña de Nabot"

    room_guesser.get night_play_path(night.code)
    assert_includes room_guesser.response.body, "¡ADIVINAD!"
    assert_includes room_guesser.response.body, "¡Gritad"
    assert_not_includes room_guesser.response.body, "escribid vuestra idea"
    assert_not_includes room_guesser.response.body, "La viña de Nabot"

    guesser.get night_play_path(night.code)
    assert_includes guesser.response.body, "¡ADIVINAD!"
    assert_not_includes guesser.response.body, "TÚ EXPLICAS"
    assert_includes guesser.response.body, "escribid vuestra idea"

    miss.post night_round_run_answer_path(night.code, taboo), params: { body: "Daniel" }
    casa.reload
    assert_not casa.score_events.where(kind: "incorrect").exists?

    guesser.post night_round_run_answer_path(night.code, taboo), params: { body: "Nabot" }
    team.reload
    assert team.score_events.where(kind: "correct").exists?

    get presenter_console_path(night.code)
    assert_includes response.body, "Han dicho una palabra"
    assert_includes response.body, "¡Lo adivinaron!"
    assert_includes response.body, "Jezabel"
  end

  test "scavenger is a hunt: room and home slam found and presenter confirms" do
    night = create_night
    hunt = night.round_runs.find_by!(yaml_round_id: "scavenger_harp")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    hunt.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, hunt)

    room = open_session
    room.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    room.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    leones = night.teams.find_by!(name: "Leones")

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    casa = night.teams.find_by!(name: "Casa")

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¡BUSCAD!"
    assert_includes room.response.body, "¡LO TENEMOS!"
    assert_includes room.response.body, "cualquier cosa que suene"
    assert_not_includes room.response.body, "El presentador dirige esta ronda"

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¡BUSCAD!"
    assert_includes remote.response.body, "En casa"
    assert_includes remote.response.body, "¡LO TENEMOS!"

    room.post night_round_run_answer_path(night.code, hunt), params: { body: "¡Lo tenemos!" }
    leones.reload
    assert leones.answers.where(round_run: hunt).exists?
    assert_not leones.score_events.where(kind: "correct").exists?

    room.get night_play_path(night.code)
    assert_includes room.response.body, "Enseñadlo"

    get presenter_console_path(night.code)
    assert_includes response.body, "Lo tienen — Leones"
    assert_includes response.body, "siguen buscando"

    post presenter_scores_path(night.code), params: { team_id: leones.id, round_run_id: hunt.id, kind: "correct" }
    leones.reload
    assert leones.score_events.where(kind: "correct").exists?

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "¡BUSCAD!"
    assert_includes watch.response.body, "¡Leones lo tiene!"

    casa.reload
    assert_not casa.answers.where(round_run: hunt).exists?
  end

  test "freeze is a stop in the room and a catch at home" do
    night = create_night
    freeze = night.round_runs.find_by!(yaml_round_id: "freeze_saul")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    freeze.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, freeze)

    room = open_session
    room.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    room.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    leones = night.teams.find_by!(name: "Leones")

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    casa = night.teams.find_by!(name: "Casa")

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¡BAILAD!"
    assert_includes room.response.body, "Dejad el teléfono en la mesa"
    assert_not_includes room.response.body, "El presentador dirige esta ronda"
    assert_not_includes room.response.body, "¡ME QUEDÉ!"

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¡BAILAD!"
    assert_includes remote.response.body, "No pulses todavía"
    assert_not_includes remote.response.body, "¡ME QUEDÉ!"

    get presenter_console_path(night.code)
    assert_includes response.body, "¡CONGELADOS!"

    post presenter_lock_round_path(night.code, freeze)
    assert freeze.reload.locked?

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¡CONGELADOS!"
    assert_includes room.response.body, "No os mováis"

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¡CONGELADOS!"
    assert_includes remote.response.body, "¡ME QUEDÉ!"

    remote.post night_round_run_freeze_path(night.code, freeze)
    casa.reload
    assert casa.score_events.where(kind: "correct", round_run: freeze).exists?

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¡Plantado!"

    post presenter_scores_path(night.code), params: { team_id: leones.id, round_run_id: freeze.id, kind: "incorrect" }
    leones.reload
    assert leones.score_events.where(kind: "incorrect", round_run: freeze).exists?

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "¡CONGELADOS!"
    assert_not_includes watch.response.body, "¡ME QUEDÉ!"
  end

  test "ordering is a tap sequence for room and remote" do
    night = create_night
    kings = night.round_runs.find_by!(yaml_round_id: "kings_order")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    kings.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, kings)

    room = open_session
    room.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    room.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    leones = night.teams.find_by!(name: "Leones")

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    casa = night.teams.find_by!(name: "Casa")

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¿Quién reinó primero?"
    assert_includes room.response.body, "Saúl"
    assert_includes room.response.body, "David"
    assert_includes room.response.body, "Salomón"
    assert_includes room.response.body, "data-controller=\"order\""
    assert_not_includes room.response.body, "El presentador dirige esta ronda"

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¿Quién reinó primero?"
    assert_includes remote.response.body, "data-controller=\"order\""
    room_keys = room.response.body.scan(/data-order-key-param="(\w+)"/).flatten
    remote_keys = remote.response.body.scan(/data-order-key-param="(\w+)"/).flatten
    assert_equal %w[david salomon saul], room_keys.sort
    assert_equal room_keys, remote_keys

    room.post night_round_run_answer_path(night.code, kings), params: { body: "saul,david,salomon" }
    leones.reload
    assert leones.score_events.where(kind: "correct", round_run: kings).exists?

    remote.post night_round_run_answer_path(night.code, kings), params: { body: "david,saul,salomon" }
    casa.reload
    assert casa.score_events.where(kind: "incorrect", round_run: kings).exists?

    get presenter_console_path(night.code)
    assert_includes response.body, "Saúl → David → Salomón"
    assert_includes response.body, "David → Saúl → Salomón"

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "¿Quién reinó primero?"
    assert_includes watch.response.body, "Poned a los reyes en su tiempo"
    assert_includes watch.response.body, "choice-token"
    assert_includes watch.response.body, "picto-circle"
    assert_not_includes watch.response.body, "luego David"
    assert_not_includes watch.response.body, "Saúl, David, Salomón"
  end

  test "solomon is a judgment room and remote both cast" do
    night = create_night
    vote = night.round_runs.find_by!(yaml_round_id: "vote_solomon")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    vote.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, vote)

    room = open_session
    room.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    room.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    leones = night.teams.find_by!(name: "Leones")

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    casa = night.teams.find_by!(name: "Casa")

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¿Quién ha mostrado más sabiduría esta noche?"
    assert_includes room.response.body, "Casa"
    assert_not_includes room.response.body, "name=\"team_id\" value=\"#{leones.id}\""
    assert_not_includes room.response.body, "El presentador dirige esta ronda"

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¿Quién ha mostrado más sabiduría esta noche?"
    assert_includes remote.response.body, "Leones"

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "choice-token"
    assert_includes watch.response.body, "emblem-leon"
    assert_includes watch.response.body, "emblem-ola"

    get presenter_console_path(night.code)
    assert_includes response.body, "Contar los votos"

    room.post night_round_run_vote_path(night.code, vote), params: { team_id: casa.id }
    assert Ballot.exists?(round_run: vote, choice_team: casa)
    assert vote.reload.open?

    remote.post night_round_run_vote_path(night.code, vote), params: { team_id: leones.id }
    assert vote.reload.locked?
    assert casa.reload.score_events.where(kind: "correct", round_run: vote).exists?
    assert leones.reload.score_events.where(kind: "correct", round_run: vote).exists?

    room.get night_play_path(night.code)
    assert_includes room.response.body, "comparten la sabiduría"

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "comparten la sabiduría"
    assert_not_includes watch.response.body, "El presentador dirige esta ronda"
  end

  test "category is a shout in the room and a list at home" do
    night = create_night
    shout = night.round_runs.find_by!(yaml_round_id: "category_prophets")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    shout.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, shout)

    room = open_session
    room.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    room.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    leones = night.teams.find_by!(name: "Leones")

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    casa = night.teams.find_by!(name: "Casa")

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¡DECID!"
    assert_includes room.response.body, "¡YA!"
    assert_includes room.response.body, "Gritad"
    assert_not_includes room.response.body, "El presentador dirige esta ronda"
    assert_not_includes room.response.body, "Isaías"

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¡DECID!"
    assert_includes remote.response.body, "Escribid tres profetas"
    assert_not_includes remote.response.body, "¡YA!"

    room.post night_round_run_answer_path(night.code, shout), params: { body: "¡Ya!" }
    leones.reload
    assert leones.answers.where(round_run: shout).exists?
    assert_not leones.score_events.where(kind: "correct").exists?

    remote.post night_round_run_answer_path(night.code, shout), params: { body: "Elías, Daniel, Isaías" }
    casa.reload
    assert casa.score_events.where(kind: "correct", round_run: shout).exists?

    get presenter_console_path(night.code)
    assert_includes response.body, "Isaías"
    assert_includes response.body, "Lo dijeron — Leones"

    post presenter_scores_path(night.code), params: { team_id: leones.id, round_run_id: shout.id, kind: "correct" }
    leones.reload
    assert leones.score_events.where(kind: "correct", round_run: shout).exists?

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "¡DECID!"
    assert_includes watch.response.body, "¡Leones ya!"
    assert_not_includes watch.response.body, "Isaías"
  end

  test "finale is a crown slam then the ceremony" do
    night = create_night
    finale = night.round_runs.find_by!(yaml_round_id: "finale_prophet")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    finale.update!(phase: "intro")
    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, finale)

    room = open_session
    room.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    room.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    leones = night.teams.find_by!(name: "Leones")
    leones.update!(cached_score: 20)

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¡TODOS DE PIE!"
    assert_includes room.response.body, "¡LA CORONA!"
    assert_includes room.response.body, "Leones va delante"
    assert_not_includes room.response.body, ">Buzz<"
    assert_not_includes room.response.body, "El presentador dirige esta ronda"

    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "¡LA CORONA!"
    assert_includes remote.response.body, "¡TODOS DE PIE!"

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "¡TODOS DE PIE!"
    assert_includes watch.response.body, "¿Qué pidió Eliseo"
    assert_not_includes watch.response.body, "doble porción"

    get presenter_console_path(night.code)
    assert_includes response.body, "¡La corona!"
    assert_not_includes response.body, "Siguiente"

    room.post night_round_run_buzz_path(night.code, finale)
    assert leones.reload.buzzes.where(round_run: finale).exists?

    post presenter_crown_path(night.code, finale)
    assert night.reload.finished?

    room.get night_play_path(night.code)
    assert_includes room.response.body, "¡TODOS DE PIE!"
    assert_includes room.response.body, "Sois los campeones."

    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "¡Leones gana la noche!"
    assert_includes watch.response.body, "Lucía"
  end

  test "finished night is a stand-up ceremony with names" do
    night = create_night
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")

    lucia = open_session
    lucia.post night_players_path(night.code), params: { name: "Lucía", location: "room" }
    lucia.post night_teams_path(night.code), params: { name: "Leones", emblem: "leon" }
    leones = night.teams.find_by!(name: "Leones")

    daniel = open_session
    daniel.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    daniel.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    casa = night.teams.find_by!(name: "Casa")
    leones.update!(cached_score: 42)
    casa.update!(cached_score: 15)

    get presenter_gate_path(night.code, token: token)
    post presenter_finish_path(night.code)

    get presenter_console_path(night.code)
    assert_includes response.body, "¡TODOS DE PIE!"
    assert_includes response.body, "¡Leones gana la noche!"
    assert_includes response.body, "Lucía"
    assert_includes response.body, "La corona se queda en esta casa."
    assert_not_includes response.body, ">Abrir<"
    assert_not_includes response.body, "Cerrar noche"

    watch = open_session
    watch.get night_watch_path(night.code)
    assert_includes watch.response.body, "¡TODOS DE PIE!"
    assert_includes watch.response.body, "Lucía"
    assert_includes watch.response.body, "Daniel"

    lucia.get night_play_path(night.code)
    assert_includes lucia.response.body, "¡TODOS DE PIE!"
    assert_includes lucia.response.body, "Sois los campeones."
    assert_includes lucia.response.body, "Lucía"

    daniel.get night_play_path(night.code)
    assert_includes daniel.response.body, "Quedáis 2.º"
  end

  test "remote player gets a skill activity for david" do
    night = create_night
    david = night.round_runs.find_by!(yaml_round_id: "david_goliath")
    token = "presenter-secret"
    night.update!(presenter_token_digest: GameSession.digest_token(token), status: "playing")
    night.round_runs.update_all(phase: "pending")
    david.update!(phase: "intro")

    get presenter_gate_path(night.code, token: token)
    post presenter_open_round_path(night.code, david)

    remote = open_session
    remote.post night_players_path(night.code), params: { name: "Daniel", location: "remote" }
    remote.post night_teams_path(night.code), params: { name: "Casa", emblem: "ola" }
    remote.get night_play_path(night.code)
    assert_includes remote.response.body, "Lanzar"
    assert_includes remote.response.body, "Fuerza"
  end
end
