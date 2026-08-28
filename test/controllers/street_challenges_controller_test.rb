require "test_helper"

class StreetChallengesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: {
      name: pili.given_name,
      favorite_year: pili.favorite_year,
      avatar_key: pili.avatar_key
    }
    follow_redirect!
  end

  test "show pending challenge" do
    duel = street_duels(:pending_challenge)
    get street_challenge_path(duel.token)
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#street_desafio.hall-paper"
    assert_select "body.is-duel-show"
    assert_select ".street-duel-arena"
    assert_select ".street-duel-moment"
    assert_select ".hall-sheet"
    assert_select "h1", text: I18n.t("street.duel_title")
    assert_select ".street-desafio-faces"
    assert_select ".street-duel-sigil img[src='/media/social/icon-challenge-medallion-v1.png']"
    assert_select ".street-duel-vs-mark", text: I18n.t("street.duel_vs")
    assert_select ".gate", count: 0
    assert_select ".btn-gold", text: I18n.t("street.duel_share_again")
    assert_select ".picto-btn", count: 0
  end

  test "invitee sees accept and the score to beat" do
    duel = street_duels(:pending_challenge)
    duel.update!(status: "challenger_done", challenger_score: 75)
    carmen = people(:carmen_garcia)
    reset!
    sign_in_congregation
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect!
    get street_challenge_path(duel.token)
    assert_response :success
    assert_select ".btn-gold", text: I18n.t("street.duel_accept")
    assert_select "p.lede", text: I18n.t("street.duel_beat_score", name: people(:pili).given_name, score: 75)
  end

  test "create returns token" do
    post street_challenges_path, params: { pack_id: "coronas" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert body["url"].present?
  end

  test "ceremony share turns the completed score into the challenge to beat" do
    person = people(:pili)
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("ceremony-share-score"),
      person:,
      pack_id: "placas",
      position: 10,
      score: 87,
      status: "finished",
      opened_at: 5.minutes.ago
    )

    post street_challenges_path, params: { pack_id: "placas", run_id: run.id }, as: :json

    assert_response :success
    duel = StreetDuel.find_by!(token: JSON.parse(response.body).fetch("token"))
    assert_equal run.id, duel.challenger_run_id
    assert_equal 87, duel.challenger_score
    assert duel.challenger_done?
  end

  test "ceremony share cannot attach another player's score" do
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("another-player-score"),
      person: people(:carmen_garcia),
      pack_id: "placas",
      position: 10,
      score: 99,
      status: "finished",
      opened_at: 5.minutes.ago
    )

    assert_no_difference("StreetDuel.count") do
      post street_challenges_path, params: { pack_id: "placas", run_id: run.id }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "opening a shared challenge records acquisition and shows the score to beat" do
    duel = street_duels(:pending_challenge)
    duel.update!(challenger_score: 75, status: "challenger_done")
    reset!

    assert_difference("ViralEvent.where(name: 'invite_link_opened').count", 1) do
      get street_challenge_path(duel.token, src: "native")
    end

    assert_response :success
    assert_select ".street-duel-score-to-beat", text: /75/
    event = ViralEvent.order(:id).last
    assert_equal "native", event.source
    assert_equal duel.id, event.street_duel_id
  end

  test "a fresh invitee creates a ficha before accepting and playing" do
    duel = street_duels(:pending_challenge)
    duel.update!(challenger_score: 75, status: "challenger_done")
    reset!

    get street_challenge_path(duel.token, src: "native")
    assert_response :success
    assert_select ".street-duel-no-account", text: I18n.t("street.duel_profile_required")

    post street_challenge_accept_path(duel.token)
    assert_redirected_to street_profile_path(quick: 1, fresh: 1)

    post street_profile_path, params: { name: "Noemi", avatar_key: "delfin", soy_nueva: 1 }
    assert_redirected_to jugar_path
    assert_equal "Noemi", duel.reload.opponent_person.given_name
    assert_equal duel.ward_id, duel.opponent_person.ward_id
    assert ViralEvent.where(street_duel: duel, name: "invitee_registered").exists?
    assert ViralEvent.where(street_duel: duel, name: "challenge_started").exists?
  end

  test "create share url uses the request host" do
    reset!
    host! "nochelive.onrender.com"
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: {
      name: pili.given_name,
      favorite_year: pili.favorite_year,
      avatar_key: pili.avatar_key
    }
    follow_redirect!

    post street_challenges_path, params: { pack_id: "coronas" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "http://nochelive.onrender.com/desafio/#{body["token"]}", body["url"]
  end

  test "accept starts opponent pack" do
    duel = street_duels(:pending_challenge)
    carmen = people(:carmen_garcia)
    reset!
    sign_in_congregation
    get root_path
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect!
    post street_challenge_accept_path(duel.token)
    assert_redirected_to jugar_path
    assert_equal carmen.id, duel.reload.opponent_person_id
  end

  test "full duel flow resolves after opponent finishes pack" do
    duel = street_duels(:pending_challenge)
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    challenger_run = QuizRun.create!(
      device_digest: GameSession.digest_token("challenger-device"),
      person_id: pili.id,
      pack_id: duel.pack_id,
      position: 10,
      score: 75,
      status: "finished",
      opened_at: 2.hours.ago
    )
    duel.update!(challenger_run:, challenger_score: 75, status: "challenger_done")

    reset!
    sign_in_congregation
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect!
    post street_challenge_accept_path(duel.token)
    follow_redirect!

    run = QuizRun.open_runs.where(person_id: carmen.id, pack_id: duel.pack_id).order(:id).last
    assert run
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    run.update!(position: 10, ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: pack.question_at(10).correct_choice)
    Quizzes::Complete.call(run: run.reload)

    duel.reload
    assert duel.resolved?
    assert_operator duel.opponent_score.to_i, :>, 0
    assert_includes [ pili.id, carmen.id ], duel.winner_person&.id
  end

  test "create without a ficha returns unauthorized json" do
    reset!
    sign_in_congregation
    post street_challenges_path, params: { pack_id: "coronas" }, as: :json
    assert_response :unauthorized
  end

  test "accepting a locked pack still starts the challenge" do
    duel = street_duels(:pending_challenge)
    duel.update!(pack_id: "placas", status: "challenger_done", challenger_score: 40)
    carmen = people(:carmen_garcia)
    reset!
    sign_in_congregation
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect!
    post street_challenge_accept_path(duel.token)
    assert_redirected_to jugar_path
    follow_redirect!
    run = QuizRun.open_runs.where(person_id: carmen.id, pack_id: "placas").order(:id).last
    assert run
    assert_equal "placas", run.pack_id
  end

  test "picking a ficha after the invite auto-starts the challenge" do
    duel = street_duels(:pending_challenge)
    carmen = people(:carmen_garcia)
    reset!
    sign_in_congregation
    get root_path
    post street_challenge_accept_path(duel.token)
    assert_redirected_to street_profile_path(quick: 1, fresh: 1)
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    assert_redirected_to jugar_path
    assert_equal carmen.id, duel.reload.opponent_person_id
  end

  test "challenge board shows stake hero active matches rivals and history" do
    get street_challenges_path
    assert_response :success
    assert_select ".street-duel-inbox"
    assert_select ".street-stake-rivalry"
    assert_select "h1", text: I18n.t("street.duel_inbox_kicker")
    assert_select ".street-duel-live-card"
    assert_select ".street-duel-pick"
    assert_select ".street-duel-history"
    assert_select ".navigation-dock", count: 1
    assert_select "a.street-duel-back[href=?]", street_leaderboard_path
  end

  test "player without a ward is asked to choose one then returns to challenges" do
    reset!
    post street_profile_path, params: { name: "Noa", avatar_key: "delfin" }
    assert_redirected_to root_path

    get street_challenges_path
    assert_redirected_to search_path(cambiar: 1)
    assert_equal I18n.t("flashes.ward_required_challenges"), flash[:alert]

    post street_ward_pick_path, params: { code: wards(:demo).code }
    assert_redirected_to street_challenges_path
  end

  test "challenge board puts live rivals first" do
    PersonDevice.create!(person: people(:carmen_lopez), device_token: "lopez-live-inbox", last_seen_at: Time.current)
    get street_challenges_path
    assert_response :success
    assert_select ".street-duel-pick li:first-child", text: /#{Regexp.escape(people(:carmen_lopez).display_name)}/
    assert_select ".street-live-dot"
    assert_select ".street-duel-rival-button", text: /#{Regexp.escape(people(:carmen_garcia).display_name)}/
  end

  test "named rematch on a resolved pack starts a new live duel" do
    carmen = people(:carmen_garcia)
    assert_difference("ViralEvent.where(name: 'rematch_started').count", 1) do
      post street_challenges_path, params: { opponent_id: carmen.id, pack_id: "coronas", source: "result-rematch" }
    end
    assert_redirected_to street_challenges_path
    assert StreetDuel.active.where(challenger_person: people(:pili), opponent_person: carmen, pack_id: "coronas").exists?
  end

  test "opponent can decline a named challenge" do
    carmen = people(:carmen_garcia)
    StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "placas",
      token: "decline-inbox-token",
      status: "challenger_done",
      challenger_score: 44,
      expires_at: 7.days.from_now
    )
    reset!
    sign_in_congregation
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect!
    post street_challenge_decline_path("decline-inbox-token")
    assert_redirected_to street_challenges_path
    assert_equal "declined", StreetDuel.find_by!(token: "decline-inbox-token").status
    follow_redirect!
    assert_select ".banner", text: I18n.t("street.duel_declined")
    assert_select ".street-duel-inbox-card-name", text: people(:pili).display_name, count: 0
  end

  test "named html create puts the opponent on the duel" do
    carmen = people(:carmen_garcia)
    QuizRun.create!(
      device_digest: GameSession.digest_token("inbox-named"),
      person: people(:pili),
      pack_id: "placas",
      position: 10,
      score: 58,
      status: "finished",
      opened_at: 1.hour.ago
    )
    post street_challenges_path, params: { opponent_id: carmen.id, pack_id: "placas" }
    assert_redirected_to street_challenges_path
    duel = StreetDuel.order(:id).last
    assert_equal carmen.id, duel.opponent_person_id
    assert_equal people(:pili).id, duel.challenger_person_id
    assert_nil duel.challenger_score
    assert duel.challenger_run.open?
    assert_equal duel.id, duel.challenger_run.street_duel_id
    follow_redirect!
    assert_select ".banner", text: I18n.t(
      "street.duel_named",
      name: carmen.display_name,
      pack: QuizDefinition.catalog.find_pack("placas").copy(:title)
    )
  end

  test "inbox without a ficha sends you to pick one" do
    reset!
    sign_in_congregation
    get street_challenges_path
    assert_redirected_to street_profile_path(quick: 1, fresh: 1)
  end

  test "ceremony turbo stream shows the duel result when both have finished" do
    duel = street_duels(:pending_challenge)
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    challenger_run = QuizRun.create!(
      device_digest: GameSession.digest_token("challenger-device-ui"),
      person_id: pili.id,
      pack_id: duel.pack_id,
      position: 10,
      score: 75,
      status: "finished",
      opened_at: 2.hours.ago
    )
    duel.update!(challenger_run:, challenger_score: 75, status: "challenger_done")

    reset!
    sign_in_congregation
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect!
    post street_challenge_accept_path(duel.token)
    follow_redirect!

    run = QuizRun.open_runs.where(person_id: carmen.id, pack_id: duel.pack_id).order(:id).last
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    run.update!(position: 10, ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: pack.question_at(10).correct_choice)
    post quiz_advance_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".street-card.is-duel"
    assert_select ".street-duel-score", text: "75"
    assert_select ".street-duel-rematch", text: I18n.t("street.duel_rematch")
    assert_select ".street-ceremony-generated-world img[src='/media/social/duel-ceremony-gateway-v1.png']"
    assert_select ".street-ceremony-victory-icon[src='/media/social/icon-victory-medallion-v1.png']"
  end
end
