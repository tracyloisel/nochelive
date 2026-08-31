require "test_helper"

class StudyJourneyTest < ActionDispatch::IntegrationTest
  setup do
    @program = StudyProgram.create!(
      slug: "come-follow-me-test", title: "Viens et suis-moi 2026", year: 2026,
      canon: "old_testament", locale: "fr", status: "published", source_url: "https://example.test/program"
    )
    @unit = @program.study_units.create!(
      slug: "week-35", kind: "week", position: 35, title: "24 – 30 août : Psaumes 49-86",
      source_url: "https://example.test/35", starts_on: Date.current.beginning_of_week,
      ends_on: Date.current.end_of_week, scripture_refs: [ "Psaumes 49-86" ], status: "published"
    )
    content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml")).dig("quizzes", 0, "content")
    @quiz = @unit.study_quiz_versions.create!(
      version: 1, status: "published", editorial_locale: "fr", content:,
      content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
    )
  end

  test "the legacy program URL returns to the single reading picker" do
    get study_program_path

    assert_redirected_to scripture_library_path(section: "program", anchor: "selection")
  end

  test "the legacy program URL preserves every active language" do
    %w[es fr en pt-BR].each do |locale|
      get study_program_path(locale:)

      assert_redirected_to scripture_library_path(locale:, section: "program", anchor: "selection")
    end
  end

  test "La Parole surfaces readings suggested by unresolved quiz answers" do
    person = people(:pili)
    sign_in_congregation(person.ward)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    question = QuizDefinition.catalog.find_pack("coronas").questions.first
    run = QuizRun.create!(person:, device_digest: "suggestion-study", pack_id: "coronas", position: 10, score: 0, status: "finished", opened_at: Time.current)
    QuizAnswer.create!(quiz_run: run, device_digest: run.device_digest, pack_id: run.pack_id, question_id: question.id, correct: false)

    get scripture_library_path

    assert_response :success
    assert_select ".scripture-library-row[data-library-row=recommendation]", text: /#{Regexp.escape(question.scripture.cite)}/
  end

  test "the legacy history URL opens bookmarks inside the single reading picker" do
    person = people(:pili)
    sign_in_congregation(person.ward)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    follow_redirect!
    person.scripture_marks.create!(
      reference: "ot/1-sam/16", locale: "fr", anchor_scope: "passage", visual_style: "none",
      start_verse: 1, start_offset: 2, end_verse: 2, end_offset: 14,
      selected_text: "dit l’Éternel à Samuel", bookmarked_at: Time.current
    )

    get study_history_path(locale: :fr)

    assert_redirected_to scripture_library_path(locale: :fr, section: "bookmarks", anchor: "selection")
    follow_redirect!
    assert_response :success
    assert_select "body.is-scripture-library.is-celestial-dark"
    assert_select ".scripture-library-row[data-library-row='bookmarks'][aria-current='true'] + turbo-frame#library_selection"
    assert_select "#selection a.scripture-library-selection__item[data-turbo-frame='scripture_reader']",
      text: /1 Samuel 16:1–2/, count: 1
  end

  test "legacy week links open that week's choices inside the full screen library" do
    get study_unit_path(@unit)

    assert_redirected_to scripture_library_path(section: "weekly", unit: @unit.id, anchor: "selection")
    follow_redirect!
    assert_response :success
    assert_select "body.is-scripture-library.is-celestial-dark"
    assert_select ".scripture-library-row[data-library-row='weekly'][aria-current='true'] + turbo-frame#library_selection"
    assert_select "#selection a.scripture-library-selection__item[data-turbo-frame='scripture_reader']", count: 10
  end

  test "study refuge bed follows the active journey and leaves before ceremony" do
    post study_run_start_path(@unit)
    run = StudyRun.last

    get study_run_path(run)
    assert_response :success
    assert_select "#study_run[data-stage-bed-value=study_refuge]"

    run.update!(status: "completed", position: 10, completed_at: Time.current)
    get study_run_path(run)
    assert_response :success
    assert_select "#study_run[data-stage-bed-value]", count: 0
  end

  test "guest can answer and advance through an immutable quiz version" do
    get study_unit_path(@unit)
    assert_redirected_to scripture_library_path(section: "weekly", unit: @unit.id, anchor: "selection")
    follow_redirect!
    assert_select "#selection a.scripture-library-selection__item[data-turbo-frame=scripture_reader]", count: 10
    assert_select "#selection a[data-scripture-chapter-title]", count: 10

    post study_run_start_path(@unit)
    assert_redirected_to study_run_path(StudyRun.last)
    run = StudyRun.last

    get study_run_path(run)
    assert_response :success
    assert_select "#study_run[data-stage-bed-value=study_refuge]"
    assert_select ".home-menu.is-hud[data-hud-theme='celestial-dark'] .quiz-hud[data-hud-theme='celestial-dark']", count: 1
    assert_select ".navigation-dock .navigation-dock__item.is-active[href='#{scripture_library_path}']", count: 1
    assert_select ".study-choice", count: 4
    assert_select "a.study-question-reading[data-turbo-frame=scripture_reader]", count: 1
    assert_select "a.study-question-reading[data-scripture-chapter-title]", count: 1

    correct = @quiz.question_at(1).fetch("correct_choice")
    run.update!(asked_at: 3.seconds.ago)
    post study_run_answers_path(run), params: { choice: correct }
    answer = run.study_answers.reload.last
    assert_redirected_to study_run_path(run, reveal: answer.id)
    assert_equal 1, run.reload.score
    assert_equal @quiz.question_at(1).fetch("key"), run.study_answers.first.question_key
    assert_in_delta 3_000, answer.duration_ms, 300

    get study_run_path(run, reveal: answer.id)
    assert_select "#study_run.is-reveal.is-reveal-correct[data-controller='study-run']"
    assert_select ".study-score-gain", text: "+1"
    assert_select ".study-choice.is-correct", count: 1
    assert_select ".study-explanation"

    post study_run_advance_path(run)
    assert_redirected_to study_run_path(run)
    assert_equal 2, run.reload.position
    assert_in_delta Time.current.to_f, run.asked_at.to_f, 1
  end

  test "opening a chapter remembers it for the current profile and marks it on the week" do
    sign_in_congregation
    person = people(:pili)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    follow_redirect!
    reading = @quiz.readings.first
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }

    assert_difference -> { ReadingProgress.where(person:, study_unit: @unit).count }, 1 do
      get scripture_path(reading.fetch("study"), cite: reading.fetch("label"), study_unit_id: @unit.id),
          headers: { "Turbo-Frame" => "scripture_reader" }
    end

    progress = ReadingProgress.find_by!(person:, study_unit: @unit, reference: reading.fetch("study"))
    assert_equal "opened", progress.status

    get scripture_library_path(section: "weekly", unit: @unit.id, anchor: "selection")
    assert_response :success
    assert_select "#selection a.scripture-library-selection__item[href*='study_unit_id=#{@unit.id}'][data-turbo-frame='scripture_reader']", count: @quiz.readings.size
  ensure
    Scriptures::Read.fetcher = nil
  end

  test "a stale journey link returns the player to their active journey" do
    post study_run_start_path(@unit)
    run = StudyRun.last

    get study_run_path(run.id + 10_000)

    assert_redirected_to study_run_path(run)
  end

  test "completed journey remains visible as ten out of ten on the home" do
    # Versions generated before chapter links were introduced remain immutable;
    # their question references still have to feed the scripture counters.
    @quiz.update_column(:content, @quiz.content.except("readings"))
    post study_run_start_path(@unit)
    run = StudyRun.last

    10.times do |index|
      question = @quiz.question_at(index + 1)
      post study_run_answers_path(run), params: { choice: question.fetch("correct_choice") }
      post study_run_advance_path(run)
    end

    assert_predicate run.reload, :completed?

    fellow_one = people(:pili)
    fellow_two = people(:carmen_garcia)
    StudyRun.create!(person: fellow_one, study_quiz_version: @quiz, device_digest: "fellow-one", position: 10, score: 8, status: "completed", opened_at: 2.days.ago, completed_at: 1.day.ago)
    StudyRun.create!(person: fellow_two, study_quiz_version: @quiz, device_digest: "fellow-two", position: 10, score: 9, status: "completed", opened_at: 2.days.ago, completed_at: 2.hours.ago)
    StudyRun.create!(person: fellow_one, study_quiz_version: @quiz, device_digest: "fellow-one-replay", position: 10, score: 10, status: "completed", opened_at: 1.day.ago, completed_at: 1.hour.ago)

    get study_run_path(run)
    assert_response :success
    assert_select "#study_run[data-stage-bed-value]", count: 0
    assert_select ".study-ceremony blockquote + a.btn.btn-gold[href='#{scripture_library_path(section: "program", anchor: "selection")}']", text: I18n.t("study.view_annual_program")
    assert_select ".study-validated-program", text: /#{Regexp.escape(@program.display_title)}/
    assert_select ".study-validated-program", text: /#{Regexp.escape(@unit.display_scripture_refs.first)}/
    assert_select "#study-finishers-title", text: I18n.t("study.finishers_title", count: 2)
    assert_select ".study-finisher", count: 2
    assert_select ".study-finisher", text: /#{Regexp.escape(fellow_one.given_name)}/, count: 1
    assert_select ".study-finisher", text: /#{Regexp.escape(fellow_two.given_name)}/, count: 1
    assert_select ".study-finisher", text: /#{Regexp.escape(fellow_two.family_name)}/, count: 0
    assert_select ".study-finisher", text: /#{Regexp.escape(wards(:demo).name)}/, minimum: 1
    assert_select "a", text: I18n.t("study.keep_light"), count: 0

    # Republishing corrected questions and starting them must never hide an
    # accomplishment recorded against the previous immutable version.
    replacement_content = @quiz.content.deep_dup
    replacement_content["revision_test"] = "corrected"
    @unit.study_quiz_versions.create!(
      version: 2,
      status: "published",
      editorial_locale: "fr",
      content: replacement_content,
      content_digest: Digest::SHA256.hexdigest(replacement_content.to_json),
      published_at: Time.current
    )
    post study_run_start_path(@unit)
    replay = StudyRun.last
    assert_equal "open", replay.status
    refute_equal run.id, replay.id
    refute_equal run.study_quiz_version_id, replay.study_quiz_version_id

    get root_path
    assert_response :success
    # This journey is anonymous: the public Hub must not invent a personal
    # reading task. A signed-in member sees the compact weekly programme route
    # (covered by the Hub controller contract); a visitor sees the public
    # adventure only.
    assert_select ".hub-now, .hub-now__programme", count: 0
  end

  test "completed journey celebrates and lists the first finisher" do
    sign_in_congregation
    person = people(:pili)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    follow_redirect!

    post study_run_start_path(@unit)
    run = StudyRun.last
    run.update!(status: "completed", position: 10, score: 10, completed_at: Time.current)

    get study_run_path(run)

    assert_response :success
    assert_select "#study-finishers-title", text: I18n.t("study.first_finisher_title")
    assert_select ".study-finisher", count: 1
    assert_select ".study-finisher strong", text: person.given_name, count: 1
  end

  test "completed journey paginates fellow finishers by cumulative groups of one hundred" do
    post study_run_start_path(@unit)
    run = StudyRun.last
    run.update!(status: "completed", position: 10, completed_at: Time.current)

    first_person_id = Person.maximum(:id).to_i + 1
    people = 101.times.map do |index|
      Person.create!(
        id: first_person_id + index,
        ward: wards(:demo), given_name: "Lecteur#{index}", family_name: "Test",
        avatar_key: "delfin", locale: "fr"
      )
    end
    now = Time.current
    StudyRun.insert_all!(people.map.with_index do |person, index|
      {
        person_id: person.id, study_quiz_version_id: @quiz.id, device_digest: "reader-#{index}",
        position: 10, score: index % 11, status: "completed", opened_at: now, completed_at: now,
        created_at: now, updated_at: now
      }
    end)

    get study_run_path(run)
    assert_response :success
    assert_select "#study-finishers-title", text: I18n.t("study.finishers_title", count: 101)
    assert_select ".study-finisher", count: 100
    assert_select "a.study-finishers-more[href='#{study_run_path(run, finishers_page: 2, anchor: "study-finishers-title")}']", text: I18n.t("study.load_more_finishers")

    get study_run_path(run, finishers_page: 2)
    assert_response :success
    assert_select ".study-finisher", count: 1
    assert_select "a.study-finishers-more", count: 0
    assert_select "a[href='#{study_run_path(run, finishers_page: 1, anchor: "study-finishers-title")}']", text: I18n.t("study.previous_finishers")
  end

  test "the legacy parish URL leaves the picker for Circle" do
    get study_community_path(ward_code: wards(:demo).code, readers_page: 2)

    assert_redirected_to scripture_circle_path
  end
end
