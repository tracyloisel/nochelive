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
    assert_select "h1", text: I18n.t("street.duel_title")
  end

  test "create returns token" do
    post street_challenges_path, params: { pack_id: "coronas" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert body["url"].present?
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
end
