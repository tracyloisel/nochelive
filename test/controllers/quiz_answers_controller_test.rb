require "test_helper"

class QuizAnswersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    create_street_profile!
    start_street_play!
  end

  test "jugar draws a street quiz and a tap settles the board" do
    get jugar_path
    assert_response :success
    assert_select "#street_quiz.play-reel.is-quiz.is-street.is-overlay.is-art-preview"
    assert_select "#street_quiz[data-stage-cue-policy-value=manual]"
    assert_select "#street_quiz[data-stage-bed-value=timer_tension][data-stage-bed-policy-value=continuous]"
    assert_select ".quiz-hud-rail"
    assert_select ".choice-btn"
    assert_select ".choice-btn .quiz-letter"
    assert_select "turbo-frame#scripture_reader"

    run = QuizRun.order(:id).last
    question = run.question
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action=quiz_deferred_replace][target=street_quiz_hud_stats]", count: 1
    assert_select "turbo-stream[action=replace][target=street_quiz_feedback]", count: 1
    assert_select "turbo-stream[action=replace][target=street_quiz_answer_panel]", count: 1
    assert_select "turbo-stream[action=replace][target=street_quiz_actions]", count: 1
    assert_select "turbo-stream[action=replace][target=street_quiz_timer]", count: 1
    assert_select "turbo-stream[action=replace][target=street_quiz_dock]", count: 0
    assert_select "turbo-stream[action=quiz_state][target=street_quiz]", count: 1
    assert_select "turbo-stream[action=replace][target=street_quiz]", count: 0
    assert_select "#street_quiz.is-art-preview", count: 0
    assert_select "#street_quiz[data-stage-sfx-value=correct_gold]"
    assert_select "#street_quiz[data-stage-bed-value=timer_tension][data-stage-bed-policy-value=continuous]"
    assert_select ".quiz-board.is-settled"
    assert_select ".quiz-bar .word"
    assert_select ".quiz-bar .quiz-meta .quiz-pct"
    assert_select ".quiz-bar .choice-mark", count: 0
    assert_select ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_select ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross"
    assert_select ".quiz-meta .quiz-flag", count: 0
    assert_select ".quiz-hud-score [data-quiz-target=score]"
    assert_select ".quiz-hud-score .picto-crown"
    assert_select ".quiz-hud .street-crowns-pop", count: 0
    assert_select ".quiz-hud-streak img.quiz-hud-streak-icon[src*='living-fire-hud-v1.webp']", count: 1
    assert_select ".quiz-hud-streak .quiz-hud-streak-multiplier", text: "×"
    assert_select ".quiz-hud-streak[data-tier=spark] .quiz-hud-streak-num", text: "1"
    assert_select "#street_quiz[data-quiz-to-score-value=?]", "5"
    shout = I18n.t("quiz.streak_start")
    assert_select ".street-praise"
    assert_select ".street-praise.is-streak.is-spark"
    assert_select ".street-praise-line", text: shout
    assert_select ".street-hit-performance[data-tier=spark]"
    assert_select ".street-hit-value.is-gain", text: "+5"
    assert_select ".street-hit-poster[src*='living-fire-poster-v1.webp']", count: 1
    assert_select ".street-hit-video source[src*='living-fire-loop-mobile-v1.webm'][media='(max-width: 767px)']", count: 1
    assert_select ".street-hit-video source[src*='living-fire-loop-v1.webm']", count: 1
    assert_select ".street-hit-points[data-quiz-target=gain]", text: I18n.t("quiz.points_gained", count: 5)
    assert_select ".street-hit-breakdown", text: I18n.t("quiz.points_breakdown_no_bonus", base: 5)
    assert_select ".street-hit-next", text: I18n.t("quiz.remaining_to_max", count: 4)
    assert_select ".street-hit-performance .picto-fire", count: 0
    assert_select ".quiz-streak-shout", count: 0
    assert_select ".quiz-hud-streak.is-shout[data-tier=spark]", count: 1
    assert_select "#street_quiz[data-quiz-combo-shout-value=start]"
    assert_select ".quiz-board.is-settled .quiz-shout", count: 0
    assert_select ".street-shot-actions .quiz-next"
    assert_select "a.quiz-scripture[data-turbo-frame=scripture_reader][href*='/escrituras/']"
    assert_select "a.quiz-scripture .quiz-read", text: I18n.t("quiz.read")
    assert_select "a.quiz-scripture .quiz-cite", text: question.scripture.cite
    assert_select "a.quiz-scripture[href*='cite=']"
    assert_select "a.quiz-scripture[href*='churchofjesuschrist.org']", count: 0
    assert_select "a.quiz-scripture[target=_blank]", count: 0
    assert_select ".quiz-board.is-settled .quiz-next", count: 0
    assert_select ".quiz-board.is-settled .quiz-scripture", count: 0
    assert_select ".street-quiz-dock", count: 0
  end

  test "a miss marks the true choice and the wrong pick" do
    run = QuizRun.order(:id).last
    question = run.question
    miss = question.choices.map { |choice| choice["key"].to_s }.find { |key| key != question.correct_choice }
    post quiz_answers_path(run), params: { choice: miss }, as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-wrong"
    assert_select "#street_quiz[data-stage-sfx-value=street_wrong_soft]"
    assert_select ".street-score span", text: "0"
    assert_select ".quiz-hud-streak[data-tier=idle] .quiz-hud-streak-num", text: "0"
    assert_select ".street-praise.is-miss"
    assert_select ".street-praise-line", text: I18n.t("quiz.not_this_time")
    assert_select ".street-hit-performance.is-break[data-streak-count=0]"
    assert_select ".street-hit-poster[src*='living-fire-dormant-v1.webp']"
    assert_select ".street-hit-video source[src*='living-fire-break-mobile-v1.webm'][media='(max-width: 767px)']"
    assert_select ".street-hit-video source[src*='living-fire-break-v1.webm']"
    assert_select ".street-hit-points.is-banked", text: I18n.t("quiz.points_banked", count: 0)
    assert_select ".street-hit-breakdown.is-lost", text: I18n.t("quiz.no_bonus_lost")
    assert_select ".quiz-shout", count: 0
    assert_select ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_select ".quiz-bar.is-wrong.is-miss .quiz-flag.is-no .picto-cross", count: 1
    assert_select ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross"
  end

  test "a duel rail announces the exact answer that passes a friend" do
    run = QuizRun.order(:id).last
    person = run.person
    target_score = run.question.points - 1
    friend_run = QuizRun.create!(
      device_digest: "duel-race-friend", person: people(:carmen_garcia), pack_id: "placas",
      position: 10, score: target_score, status: "finished", opened_at: 1.hour.ago
    )
    invitation = DuelInvitation.create!(
      challenger_person: people(:carmen_garcia), recipient_person: person,
      challenger_run: friend_run, challenger_score: target_score,
      token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    duel = Quizzes::DuelInvitationClaim.call(invitation:, person:).duel
    run.update!(opened_at: duel.accepted_at + 1.second)

    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream

    assert_response :success
    assert_select "#duel_quiz_race .duel-quiz-rail.is-you_passed.is-race-expanded.is-race-pending[aria-live=polite][data-duel-race-event-value=you_passed][data-duel-race-run-value=?]", run.id.to_s
    assert_select "#duel_quiz_race .duel-quiz-rail[data-duel-race-race-value=?][data-duel-race-signature-value]", duel.id.to_s
    assert_select ".duel-quiz-rail-copy", text: /#{Regexp.escape(people(:carmen_garcia).given_name)}/
    assert_select ".duel-quiz-rail-score", text: /#{run.reload.score}/
  end

  test "the combo stays in the HUD after next and a miss snuffs it" do
    run = QuizRun.order(:id).last
    question = run.question
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    post quiz_advance_path(run), as: :turbo_stream
    get jugar_path
    assert_select ".quiz-hud-streak[data-tier=spark] .quiz-hud-streak-num", text: "1"
    assert_select "#street_quiz[data-quiz-streak-value=1]"
    assert_select ".quiz-streak-shout", count: 0
    assert_select ".street-praise.is-streak", count: 0

    run.reload
    miss = (run.question.choices.map { |choice| choice["key"].to_s }.find { |key| key != run.question.correct_choice })
    post quiz_answers_path(run), params: { choice: miss }, as: :turbo_stream
    assert_select ".quiz-hud-streak.is-break img.quiz-hud-streak-icon[src*='living-fire-dormant-hud-v1.webp']", count: 1
    assert_select ".quiz-hud-streak.is-break[data-tier=idle] .quiz-hud-streak-num", text: "0"
    assert_select "#street_quiz[data-stage-sfx-value=street_wrong_soft]"
    assert_select ".street-praise.is-streak-break"
    assert_select ".street-praise-line", text: I18n.t("quiz.streak_break_title")
    assert_select ".street-hit-next", text: I18n.t("quiz.streak_restart")
    assert_select ".street-hit-performance.is-break[data-streak-count=0]"
    assert_select ".street-hit-prior", text: I18n.t("quiz.combo", count: 1)
    assert_select ".street-hit-performance.is-break .picto-fire", count: 0
  end

  test "two hits shout on the still and ten hits flash the gold veil" do
    run = QuizRun.order(:id).last
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    post quiz_advance_path(run), as: :turbo_stream
    run.reload
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    assert_select ".street-praise.is-streak.is-glow .street-praise-line", text: I18n.t("quiz.streak_two")
    assert_select ".street-hit-performance[data-tier=glow] .street-hit-value.is-gain", text: "+7"
    assert_select ".street-hit-breakdown", text: I18n.t("quiz.points_breakdown_with_bonus", base: 5, bonus: 2)
    assert_select ".street-hit-next", text: I18n.t("quiz.remaining_to_max", count: 3)
    assert_select "#street_quiz[data-quiz-fire-cue-value=fire_whoosh]"
    assert_select ".quiz-hud-streak.is-shout[data-tier=glow] .quiz-hud-streak-num", text: "2"
    assert_select ".quiz-streak-shout", count: 0
    assert_select "#street_quiz[data-quiz-combo-shout-value=two]"

    post quiz_advance_path(run), as: :turbo_stream
    run.reload
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    assert_select ".street-hit-next", text: I18n.t("quiz.remaining_to_max", count: 2)

    post quiz_advance_path(run), as: :turbo_stream
    run.reload
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    assert_select ".street-hit-performance[data-streak-count=4] .street-hit-value.is-gain", text: "+9"
    assert_select ".street-hit-next", text: I18n.t("quiz.remaining_to_max", count: 1)

    6.times do
      post quiz_advance_path(run), as: :turbo_stream
      run.reload
      post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    end
    assert_select ".street-praise.is-streak.is-legend .street-praise-line", text: I18n.t("quiz.streak_ten")
    assert_select ".street-hit-performance[data-tier=legend] .street-hit-value.is-gain", text: "+10"
    assert_select ".street-hit-next.is-max", text: I18n.t("quiz.bonus_max_active", bonus: 5)
    assert_select ".quiz-hud-streak.is-shout[data-tier=legend] .quiz-hud-streak-num", text: "10"
    assert_select "#street_quiz[data-quiz-combo-shout-value=ten]"
    assert_select "#street_quiz[data-stage-cue-policy-value=manual]"
    assert_select "#street_quiz[data-stage-fx-value]", count: 0
    assert_select "#street_quiz.is-ceremony", count: 0
    assert_select "turbo-stream[action=replace][target=street_quiz_dock]", count: 0
    assert_select "#street_quiz_answer_panel .quiz-bar", count: 4
    assert_select ".quiz-next", text: /#{Regexp.escape(I18n.t("quiz.results"))}/

    get jugar_path
    assert_select ".quiz-sheet .quiz-prompt", text: run.question.copy(:question)
    assert_select ".quiz-sheet .quiz-bar", count: 4
    assert_select "#street_quiz.is-ceremony", count: 0
  end

  test "rewind shows the prior settled question and will not skip an ask" do
    run = QuizRun.order(:id).last
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    post quiz_rewind_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-settled"
  end

  test "advance on the last question opens the pack ceremony" do
    run = QuizRun.order(:id).last
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    question = pack.question_at(10)
    run.update!(position: 10, score: 80, ends_at: nil)
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    run.quiz_answers.update_all(duration_ms: 77_000)
    post quiz_advance_path(run), as: :turbo_stream
    assert_response :success
    assert_select "#street_quiz.is-overlay.is-ceremony"
    assert_select "#street_quiz[data-stage-sfx-value=street_royal_fanfare]"
    assert_select "#street_quiz[data-stage-bed-value]", count: 0
    assert_select ".quiz-hud"
    assert_select ".street-ceremony-hero"
    assert_select ".street-ceremony-shout"
    assert_select ".street-ceremony-kicker"
    assert_select ".street-ceremony-medallion"
    assert_select ".street-ceremony-stats .street-ceremony-stat", count: 4
    assert_select ".street-ceremony-stat", text: /01:17/
    assert_select ".street-ceremony-boards .street-ceremony-board", count: 1
    assert_select ".street-ceremony-board-kicker", text: I18n.t("street.ceremony_board_kicker")
    assert_select ".street-ceremony-best-score .picto-crown", minimum: 1
    assert_select ".street-ceremony-chest-img"
    assert_select "button.street-ceremony-chest-wrap[data-action='click->street-motion#replayChest'][aria-label=?]", I18n.t("street.ceremony_chest_replay")
    assert_select ".street-ceremony-crowns", text: I18n.t("chrome.crowns_word")
    assert_select ".street-ceremony-map", text: I18n.t("street.ceremony_back_map")
    assert_select ".street-ceremony-map .street-ceremony-button-icon"
    assert_select ".street-ceremony-map .street-ceremony-button-label"
    assert_select ".street-challenge-btn .street-ceremony-button-tail"
    assert_select ".street-ceremony-actions > .street-ceremony-viral-cta[data-action='street-share#challenge'][data-street-share-run-id-value='#{run.id}']"
    assert_select ".street-ceremony-share .street-ceremony-button-label", text: I18n.t("duel_campus.actions.invite_from_score")
    assert_select ".quiz-hud-gain"
    assert_select ".quiz-hud-streak-tag"
    assert_select ".quiz-hud-dot.is-done", count: 10
    assert_select "#street_quiz[data-stage-cue-policy-value=manual]"
    assert_select "#street_quiz[data-stage-fx-value]", count: 0
    assert_select ".street-ceremony-lockup", count: 0
    assert_select ".street-ceremony-plinth", count: 0
    assert_select ".street-win-score.score-fly" do |nodes|
      score = nodes.first
      refute_equal "0", score["data-final"]
      assert score["data-from"].present?
    end
  end

  test "pack ceremony names the duel winner and separates both scores" do
    run = QuizRun.order(:id).last
    person = run.person
    friend = people(:carmen_garcia)
    friend_run = QuizRun.create!(
      device_digest: "ceremony-result-friend", person: friend, pack_id: "placas",
      position: 10, score: 150, status: "finished", opened_at: 1.hour.ago
    )
    invitation = DuelInvitation.create!(
      challenger_person: friend, recipient_person: person,
      challenger_run: friend_run, challenger_score: friend_run.score,
      token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    duel = Quizzes::DuelInvitationClaim.call(invitation:, person:).duel
    run.update!(opened_at: duel.accepted_at + 1.second, position: 10, score: 66, ends_at: nil)
    patch locale_path, params: { locale: "fr" }, headers: { "HTTP_REFERER" => jugar_url }

    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    post quiz_advance_path(run), as: :turbo_stream

    assert_response :success
    assert duel.reload.resolved?
    mine = duel.score_for(person)
    theirs = duel.other_score_for(person)
    gap = (mine - theirs).abs
    assert_select "#street_quiz[data-quiz-theme='dark'][data-quiz-atmosphere='dramatic']"
    assert_select ".duel-ceremony-world.is-duel-rematch picture img[src*='campus-duel-rematch-storm-v1']"
    assert_select ".street-ceremony-shout", text: "#{friend.given_name} garde l’avantage"
    assert_select ".street-ceremony-kicker", text: "Ton score : #{mine} couronnes. Écart à combler : #{gap} couronnes."
    assert_select ".duel-ceremony-impact > header h2", text: I18n.t("duel_campus.outcomes.behind", locale: :fr, name: friend.given_name)
    assert_select ".duel-ceremony-impact > header p", text: I18n.t("duel_campus.ceremony.margin.behind", locale: :fr, name: friend.given_name, crowns: gap)
    assert_select ".duel-ceremony-versus" do
      assert_select ".duel-ceremony-score-side.is-me", text: /Moi\s*#{mine}\s*couronnes/i
      assert_select ".duel-ceremony-versus-mark", text: "contre"
      assert_select ".duel-ceremony-score-side.is-friend.is-winner", text: /#{friend.given_name}\s*#{theirs}\s*couronnes/i
    end
    assert_select ".duel-ceremony-impact > .btn", text: I18n.t("duel_campus.ceremony.actions.behind", locale: :fr)
    refute_includes response.body, "défi mis à jour"
    refute_includes response.body, "Incroyable"
  end

  test "expire freezes a miss" do
    run = QuizRun.order(:id).last
    run.update!(position: 4, ends_at: 1.second.ago)
    post quiz_expire_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-wrong"
    assert_select ".street-praise.is-miss"
  end
end
