require "test_helper"

class StreetQuizHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
  end

  test "requires the profile recognized on this device" do
    get player_quiz_history_path(people(:pili))

    assert_redirected_to street_profile_path(quick: 1)
  end

  test "shows only the current player's answers with verdict choices and time" do
    person = people(:pili)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    question = QuizDefinition.catalog.find_pack("coronas").question_at(1)
    run = quiz_runs(:pili_coronas)
    run.quiz_answers.create!(
      device_digest: run.device_digest,
      pack_id: run.pack_id,
      question_id: question.id,
      choice_key: "saul",
      correct: false,
      duration_ms: 4_200
    )
    other = quiz_runs(:carmen_coronas)
    other_question = QuizDefinition.catalog.find_pack("coronas").question_at(2)
    other.quiz_answers.create!(
      device_digest: other.device_digest,
      pack_id: other.pack_id,
      question_id: other_question.id,
      choice_key: other_question.correct_choice,
      correct: true,
      duration_ms: 9_900
    )

    get player_quiz_history_path(person, locale: :fr)

    assert_response :success
    assert_select "body.is-profile-answer-history"
    assert_select "h1", text: I18n.t("street.quiz_history.title", locale: :fr)
    assert_select "a.profile-answer-back[href=?]", player_profile_path(person)
    assert_select ".profile-answer-row.is-wrong", count: 1
    assert_select ".profile-answer-row", text: /Saül/
    assert_select ".profile-answer-row", text: /Samuel/
    assert_select ".profile-answer-duration", text: /4[,.]2/
    assert_select ".profile-answer-row", text: /#{Regexp.escape(I18n.t("street.quiz_history.result_wrong", locale: :fr))}/
    assert_select ".profile-answer-row", text: /#{Regexp.escape(other_question.copy(:question))}/, count: 0
    assert_select ".navigation-dock__item.is-active[href=?]", player_profile_path(person)
  end

  test "shows an honest empty state" do
    person = people(:carmen_lopez)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }

    get player_quiz_history_path(person)

    assert_response :success
    assert_select ".profile-answer-session", count: 0
    assert_select ".profile-answer-empty h2", text: I18n.t("street.quiz_history.empty_title")
    assert_select "a.profile-glass-primary[href=?]", street_map_path
  end

  test "does not expose another player's answer history" do
    person = people(:pili)
    other = people(:carmen_garcia)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }

    get player_quiz_history_path(other)

    assert_response :not_found
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end
end
