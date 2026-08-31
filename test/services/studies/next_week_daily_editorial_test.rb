require "test_helper"

module Studies
  class NextWeekDailyEditorialTest < ActiveSupport::TestCase
    SCHEDULE_PATH = Rails.root.join(
      "config/study/library_daily_editorials/2026-09-07-prov1-3-4-15-16-22-31-eccl1-3-12.yml"
    )

    setup do
      @schedule = DailyEditorialSchedule.load(SCHEDULE_PATH)
      @zone = Time.find_zone!("Europe/Madrid")
      @directory = Dir.mktmpdir("authorized-next-week-editorial")
      @authorized_schedule_path = Pathname(@directory).join(SCHEDULE_PATH.basename)
      authorized_data = YAML.safe_load_file(SCHEDULE_PATH, aliases: false)
      authorized_data["publication"].merge!(
        "state" => "scheduled",
        "authorized_by" => "Test editor",
        "authorized_on" => "2026-09-01"
      )
      @authorized_schedule_path.write(YAML.dump(authorized_data))
      @program = StudyProgram.create!(
        slug: @schedule.program_slug,
        title: "Suis-moi — Ancien Testament 2026",
        year: 2026,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://www.churchofjesuschrist.org/study/manual/come-follow-me-for-home-and-church-old-testament-2026"
      )
      @unit = @program.study_units.create!(
        slug: @schedule.study_unit_slug,
        kind: "week",
        position: 37,
        title: "7–13 septembre : Proverbes ; Ecclésiaste",
        source_url: "https://www.churchofjesuschrist.org/study/manual/come-follow-me-for-home-and-church-old-testament-2026/37?lang=fra",
        starts_on: @schedule.starts_on,
        ends_on: @schedule.ends_on,
        scripture_refs: @schedule.discoveries.flat_map { |row| row.fetch("references") }.uniq,
        copy: Locale::AVAILABLE.index_with { |locale| { "title" => "#{locale} wisdom week" } },
        status: "published"
      )
      source_content = week_37_source.fetch("content")
      @source = @unit.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content: source_content,
        content_digest: StudyQuizVersion.content_digest_for(source_content),
        published_at: @zone.local(2026, 8, 31, 20)
      )
    end

    teardown do
      FileUtils.remove_entry(@directory) if @directory && File.directory?(@directory)
    end

    test "the real future file remains publish-ready until a human authorizes it" do
      assert_equal "publish_ready", @schedule.workflow_state

      result = PublishScheduledDailyEditorials.call(
        at: @zone.local(2026, 9, 1, 22, 30),
        paths: [ SCHEDULE_PATH ]
      ).sole

      assert_equal :not_authorized, result.database_state
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "the real future file passes a read-only database preflight before authorization" do
      result = DailyEditorialPreflight.call(schedule: @schedule)

      assert result.ready, result.message
      assert_equal @program.id, result.program_id
      assert_equal @unit.id, result.study_unit_id
      assert_equal @source.id, result.quiz_version_id
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "preflight rejects an unpublished programme" do
      @program.update!(status: "draft")

      result = DailyEditorialPreflight.call(schedule: @schedule)

      refute result.ready
      assert_equal "study program is not published", result.message
    end

    test "preflight rejects an unpublished study week" do
      @unit.update!(status: "needs_review")

      result = DailyEditorialPreflight.call(schedule: @schedule)

      refute result.ready
      assert_equal "study unit is not published", result.message
    end

    test "preflight rejects a stale base quiz digest" do
      changed = @source.content.deep_dup
      changed["preflight_tampering"] = true
      @source.update_column(:content, changed)

      result = DailyEditorialPreflight.call(schedule: @schedule)

      refute result.ready
      assert_equal "published base quiz is not current", result.message
    end

    test "the real September edition is imported ahead and changes at Madrid midnight only" do
      result = PublishScheduledDailyEditorials.call(
        at: @zone.local(2026, 8, 31, 22, 30),
        paths: [ @authorized_schedule_path ],
        root: @directory
      ).sole

      assert_equal :published, result.database_state, result.message
      assert_equal :scheduled, result.phase
      assert_equal 2, @unit.published_quiz.version
      assert_equal @schedule.expected_discoveries_digest,
        StudyQuizVersion.content_digest_for(@unit.published_quiz.daily_discoveries)

      sunday = ScriptureLibraries::Screen.call(
        person: nil,
        locale: :fr,
        at: @zone.local(2026, 9, 6, 23, 59, 59)
      )
      assert_nil sunday.editorial

      monday = ScriptureLibraries::Screen.call(
        person: nil,
        locale: :fr,
        at: @zone.local(2026, 9, 7, 0, 0, 0)
      )
      assert_equal @unit.id, monday.week.id
      assert_equal "wisdom-2026-09-07-day-1-prov1", monday.editorial.id
      assert_equal Date.new(2026, 9, 7), monday.editorial.scheduled_on
      assert_equal "La sagesse n’attend pas le silence", monday.editorial.title
    end

    test "all seven real dates resolve to exactly one different approved editorial" do
      PublishScheduledDailyEditorials.call(
        at: @zone.local(2026, 8, 31, 22, 30),
        paths: [ @authorized_schedule_path ],
        root: @directory
      )
      quiz = @unit.published_quiz

      results = (Date.new(2026, 9, 7)..Date.new(2026, 9, 13)).map do |date|
        Expeditions::DailyDiscovery.call(
          quiz:,
          locale: :fr,
          at: @zone.local(date.year, date.month, date.day, 12),
          time_zone: "Europe/Madrid"
        )
      end

      assert results.all?
      assert_equal 7, results.map(&:id).uniq.size
      assert_equal @schedule.discoveries.pluck("id"), results.map(&:id)
      assert_equal [ *Array.new(6, "discovery"), "contemplation" ], results.map(&:kind)
      assert_nil Expeditions::DailyDiscovery.call(
        quiz:,
        locale: :fr,
        at: @zone.local(2026, 9, 14, 0, 0, 0),
        time_zone: "Europe/Madrid"
      )
    end

    private

      def week_37_source
        YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml"), aliases: false)
          .fetch("quizzes")
          .find { |entry| entry.fetch("source_page") == "37" }
      end
  end
end
