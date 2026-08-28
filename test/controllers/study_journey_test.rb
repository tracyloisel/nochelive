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

  test "program exposes the current week and every appendix section" do
    4.times do |index|
      @program.study_units.create!(
        slug: "appendix-#{index}", kind: "appendix", position: index + 1,
        title: "Annexe #{('A'.ord + index).chr} : Ressource", source_url: "https://example.test/a#{index}", status: "imported"
      )
    end

    get study_program_path

    assert_response :success
    assert_select "#study_program"
    assert_select ".study-current", text: /#{Regexp.escape(I18n.t("study.psalms_theme"))}/
    assert_select ".study-path-nav", count: 0
    assert_select "a.study-profile-invite[href='#{street_profile_path(fresh: 1)}']", text: /#{Regexp.escape(I18n.t("study.profile_invite_cta"))}/
    assert_select ".navigation-dock .navigation-dock__item.is-active[href='#{study_program_path}']"
    assert_select ".study-appendix-row", count: 4

    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_match(/\.study-world > \*/, css)
    refute_match(/\.study-world > :not\(\.navigation-dock\)/, css)

    person = people(:pili)
    sign_in_congregation(person.ward)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    assert_redirected_to root_path

    get study_program_path
    assert_response :success
    assert_select ".study-profile-invite", count: 0
    assert_select ".study-path-nav a[href='#{study_community_path(ward_code: person.ward.code)}']", text: I18n.t("study.ward")
  end

  test "history page is not routed" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/parole/historique", method: :get)
    end
  end

  test "week page keeps its paper column inside a fullscreen artwork scene" do
    get study_unit_path(@unit)

    assert_response :success
    assert_select "body.is-study-unit main.shell #study_unit.study-unit-world"
    assert_select "#study_unit > .study-lockup" do
      assert_select ".study-seal", text: "✦"
      assert_select "h1", text: I18n.t("study.title")
      assert_select "p", text: I18n.t("study.motto")
    end
    assert_select "#study_unit .study-unit-sheet"

    css = Rails.root.join("app/assets/stylesheets/application.css").read
    fullscreen_shell = css[/body\.is-study-unit \.shell \{[^}]+\}/m]
    assert fullscreen_shell, "expected the study unit shell to own the full viewport"
    assert_match(/width: 100%/, fullscreen_shell)
    assert_match(/max-width: none/, fullscreen_shell)
    assert_match(/padding: 0/, fullscreen_shell)
    assert_match(/\.study-unit-sheet \{ width: min\(100%, 42rem\)/, css)
    assert_match(/\.study-unit-world \{[\s\S]*?--street-hub-col: 24\.375rem/, css)
    assert_match(/\.study-unit-world \{[\s\S]*?padding-top: max\(5\.5rem/, css)
    assert_match(/@media \(min-width: 1024px\) \{[\s\S]*?\.study-unit-world \{ --street-hub-col: 44rem; \}/, css)
    assert_match(/\.home-menu\.is-hud \{[^}]*position: fixed;[^}]*left: env\(safe-area-inset-left\);[^}]*right: env\(safe-area-inset-right\);[^}]*width: auto;[^}]*transform: none;/m, css)
    assert_match(/\.navigation-dock \{[^}]*position: fixed;[^}]*left: 0;[^}]*right: 0;[^}]*transform: none;[^}]*width: auto;/m, css)
    assert_select "body > .home-menu.is-hud", count: 1
    assert_select "body > .navigation-dock", count: 1
    assert_select "#study_unit > .home-menu", count: 0
    assert_select "#study_unit > .navigation-dock", count: 0
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
    assert_response :success
    assert_select ".study-reading-gate"
    assert_select "a.study-reading-link[data-turbo-frame=scripture_reader]", count: 10
    assert_select "[data-scripture-progress]", count: 0
    assert_select "[data-scripture-reading-link]", count: 0

    post study_run_start_path(@unit)
    assert_redirected_to study_run_path(StudyRun.last)
    run = StudyRun.last

    get study_unit_path(@unit)
    assert_select "a.study-unit-continue[href='#{study_run_path(run)}']", text: I18n.t("study.continue")
    assert_select ".study-unit-continue .picto-arrow", count: 1
    assert_select "a.quiet-link[href='#{study_program_path}']", text: I18n.t("study.back_program")

    get study_run_path(run)
    assert_response :success
    assert_select "#study_run[data-stage-bed-value=study_refuge]"
    assert_select ".home-menu.is-hud .quiz-hud", count: 1
    assert_select ".navigation-dock .navigation-dock__item.is-active[href='#{study_program_path}']", count: 1
    assert_select ".study-choice", count: 4
    assert_select "a.study-question-reading[data-turbo-frame=scripture_reader]", count: 1

    correct = @quiz.question_at(1).fetch("correct_choice")
    post study_run_answers_path(run), params: { choice: correct }
    answer = run.study_answers.reload.last
    assert_redirected_to study_run_path(run, reveal: answer.id)
    assert_equal 1, run.reload.score
    assert_equal @quiz.question_at(1).fetch("key"), run.study_answers.first.question_key

    get study_run_path(run, reveal: answer.id)
    assert_select "#study_run.is-reveal.is-reveal-correct[data-controller='study-run']"
    assert_select ".study-score-gain", text: "+1"
    assert_select ".study-choice.is-correct", count: 1
    assert_select ".study-explanation"

    post study_run_advance_path(run)
    assert_redirected_to study_run_path(run)
    assert_equal 2, run.reload.position
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

    get study_unit_path(@unit)
    assert_select ".study-reading-progress", text: I18n.t("study.readings_opened", opened: 1, total: @quiz.readings.size)
    assert_select ".study-reading-link.is-opened[href*='study_unit_id=#{@unit.id}']", text: /#{Regexp.escape(I18n.t("study.already_opened"))}/, count: 1
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
    assert_select ".study-ceremony blockquote + a.btn.btn-gold[href='#{study_program_path}']", text: I18n.t("study.view_annual_program")
    assert_select ".study-validated-program", text: /#{Regexp.escape(@program.title)}/
    assert_select ".study-validated-program", text: /#{Regexp.escape(@unit.scripture_refs.first)}/
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
    assert_select ".hub-study-progress strong", text: "10/10"
    assert_select "a.hub-study[href='#{study_program_path}']" do
      assert_select ".hub-study-action", text: I18n.t("study.continue")
      assert_select ".hub-study-action[href]", count: 0
    end
    assert_select "a.hub-study a", count: 0

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

  test "ward conversation page presents the week and only readers who finished it" do
    finished_reader = people(:pili)
    reading_reader = people(:carmen_garcia)
    StudyRun.create!(person: finished_reader, study_quiz_version: @quiz, device_digest: "finished-reader", position: 10, score: 8, status: "completed", opened_at: 2.days.ago)
    StudyRun.create!(person: reading_reader, study_quiz_version: @quiz, device_digest: "reading-reader", position: 4, score: 3, status: "open", opened_at: 1.day.ago)
    sign_in_congregation(wards(:demo))

    get study_community_path(ward_code: wards(:demo).code)

    assert_response :success
    assert_select "body.is-study-community main.shell #study_community.study-community-world"
    assert_select "#study_community[style*='community-scripture-gathering-v1.png']"
    assert_select ".study-community-week", text: /#{Regexp.escape(@unit.scripture_refs.first)}/
    assert_select ".study-community-ward-link[href='#{ward_profile_path(wards(:demo).code)}']"
    assert_select ".study-community-invite", text: /#{Regexp.escape(I18n.t("study.community_finished_total", count: 1))}/
    assert_select ".study-community-list article", count: 1
    assert_select ".study-community-list", text: /#{finished_reader.given_name}/
    assert_select ".study-community-list", text: /#{reading_reader.given_name}/, count: 0
    assert_select ".study-community-week + .study-community-actions" do
      assert_select "a.btn.btn-gold[href='#{study_unit_path(@unit)}']", text: I18n.t("study.community_read_week")
      assert_select "a[href='#{study_program_path}']", text: I18n.t("study.back_program")
    end
    assert_select ".study-community-actions + .study-community-invite"
    assert_select "#study-community-readers", text: I18n.t("study.community_finished_total", count: 1)

    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_match(/body\.is-study-community \.shell \{[^}]*width: 100%;[^}]*max-width: none/m, css)
    assert_match(/\.home-menu\.is-hud \{[^}]*position: fixed;[^}]*left: env\(safe-area-inset-left\);[^}]*right: env\(safe-area-inset-right\);[^}]*width: auto;[^}]*max-width: none;/m, css)
  end

  test "ward conversation page paginates completed readers one hundred at a time" do
    first_person_id = Person.maximum(:id).to_i + 1
    readers = 101.times.map do |index|
      Person.create!(id: first_person_id + index, ward: wards(:demo), given_name: "Paroissien#{index}", family_name: "Test", avatar_key: "delfin", locale: "fr")
    end
    now = Time.current
    StudyRun.insert_all!(readers.map.with_index do |person, index|
      { person_id: person.id, study_quiz_version_id: @quiz.id, device_digest: "ward-reader-#{index}", position: 10,
        score: index % 11, status: "completed", opened_at: now, completed_at: now, created_at: now, updated_at: now }
    end)

    get study_community_path(ward_code: wards(:demo).code)
    assert_response :success
    assert_select "#study-community-readers", text: I18n.t("study.community_finished_total", count: 101)
    assert_select ".study-community-list article", count: 100
    assert_select "a.study-community-more[href='#{study_community_path(ward_code: wards(:demo).code, readers_page: 2, anchor: "study-community-readers")}']"

    get study_community_path(ward_code: wards(:demo).code, readers_page: 2)
    assert_response :success
    assert_select ".study-community-list article", count: 1
    assert_select "a.study-community-more", count: 0
  end
end
