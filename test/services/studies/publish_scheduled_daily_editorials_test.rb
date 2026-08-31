require "test_helper"
require "tmpdir"

module Studies
  class PublishScheduledDailyEditorialsTest < ActiveSupport::TestCase
    setup do
      @starts_on = Date.new(2098, 9, 8)
      @zone = Time.find_zone!("Europe/Madrid")
      @program = StudyProgram.create!(
        slug: "scheduled-editorial-#{SecureRandom.hex(6)}",
        title: "Programme editorial programme",
        year: 2098,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/scheduled-editorial"
      )
      @unit = @program.study_units.create!(
        slug: "week-next",
        kind: "week",
        position: 37,
        title: "8–14 septembre : Proverbes ; Ecclésiaste",
        source_url: "https://example.test/scheduled-editorial/week",
        starts_on: @starts_on,
        ends_on: @starts_on + 6.days,
        scripture_refs: [ "Proverbes ; Ecclésiaste" ],
        copy: Locale::AVAILABLE.index_with { |locale| { "title" => "#{locale} wisdom week" } },
        status: "published"
      )
      source_content = {
        "questions" => Array.new(10) { |index| { "key" => "q#{index}" } },
        "readings" => [
          {
            "study" => "ot/ps/102",
            "labels" => Locale::AVAILABLE.index_with { |locale| "#{locale} Psalm 102" }
          }
        ]
      }
      @source = @unit.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content: source_content,
        content_digest: StudyQuizVersion.content_digest_for(source_content),
        published_at: @zone.local(2098, 9, 1, 12)
      )
      @directory = Dir.mktmpdir("library-editorials")
      @path = Pathname(@directory).join("2098-09-08-proverbs-ecclesiastes.yml")
      @dossier_relative = "config/expeditions/test-scheduled-editorial-#{SecureRandom.hex(6)}.yml"
      @dossier_path = Rails.root.join(@dossier_relative)
      discoveries = daily_discoveries
      dossier_days = discoveries.map do |row|
        row.slice("id", "scheduled_on", "kind", "references", "claim_ids")
          .transform_keys { |key| key == "id" ? "day_id" : key }
      end
      @dossier_path.write(YAML.dump({
        "kind" => "expedition_council_dossier",
        "lifecycle" => { "current_revision" => 1 },
        "brief" => {
          "schedule" => {
            "starts_on" => @starts_on.iso8601,
            "ends_on" => (@starts_on + 6.days).iso8601,
            "timezone" => "Europe/Madrid"
          }
        },
        "library_editorial" => {
          "revision" => 1,
          "required_locales" => Locale::AVAILABLE,
          "starts_on" => @starts_on.iso8601,
          "ends_on" => (@starts_on + 6.days).iso8601,
          "timezone" => "Europe/Madrid",
          "composition" => {
            "discoveries" => 6,
            "contemplations" => 1,
            "total_days" => 7
          },
          "expected_discoveries_digest" => StudyQuizVersion.content_digest_for(discoveries),
          "expected_artwork_digest" => DailyEditorialSchedule.artwork_digest_for(discoveries),
          "plan" => { "days" => dossier_days }
        }
      }))
    end

    teardown do
      FileUtils.remove_entry(@directory) if @directory && File.directory?(@directory)
      File.delete(@dossier_path) if @dossier_path&.file?
    end

    test "a publish-ready file remains code-only and does not mutate the database" do
      write_schedule(state: "publish_ready")

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert_equal :not_authorized, result.database_state, result.message
      assert_equal :awaiting_authorization, result.phase
      assert_equal 1, @unit.study_quiz_versions.count
      assert_equal @source.id, @unit.published_quiz.id
    end

    test "an incomplete draft can live in the codebase without publication or worker failure" do
      @path.write(YAML.dump({ "publication" => { "state" => "draft" } }))

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert_equal :not_authorized, result.database_state
      assert_equal :draft, result.phase
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "the publication worker rejects an invalid publish-ready file" do
      @path.write(YAML.dump({ "publication" => { "state" => "publish_ready" } }))

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert result.error?
      assert_includes result.message, "schema_version must be one of"
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "an unknown workflow state fails loudly instead of disappearing from the queue" do
      @path.write(YAML.dump({ "publication" => { "state" => "schedueld" } }))

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert result.error?
      assert_includes result.message, "publication.state must be one of"
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "an explicitly empty path selection publishes nothing" do
      write_schedule(state: "scheduled")

      results = PublishScheduledDailyEditorials.call(
        at: @zone.local(2098, 9, 2, 12),
        paths: [],
        root: @directory
      )

      assert_empty results
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "an explicit schedule path cannot escape its configured root" do
      write_schedule(state: "scheduled")
      other_directory = Dir.mktmpdir("outside-library-editorials")

      error = assert_raises(PublishScheduledDailyEditorials::Error) do
        PublishScheduledDailyEditorials.call(
          at: @zone.local(2098, 9, 2, 12),
          paths: [ @path ],
          root: other_directory
        )
      end

      assert_includes error.message, "schedule path must remain inside"
    ensure
      FileUtils.remove_entry(other_directory) if other_directory && File.directory?(other_directory)
    end

    test "an explicitly scheduled future edition is published ahead but hidden until its local date" do
      write_schedule(state: "scheduled")
      prepared_at = @zone.local(2098, 9, 2, 12)

      result = publish(at: prepared_at).sole
      published = @unit.published_quiz

      assert_equal :published, result.database_state, result.message
      assert_equal :scheduled, result.phase
      assert_equal 2, published.version
      assert_equal "retired", @source.reload.status
      assert_nil Expeditions::DailyDiscovery.call(
        quiz: published,
        locale: :fr,
        at: @zone.local(2098, 9, 7, 23, 59, 59),
        time_zone: "Europe/Madrid"
      )

      discovery = Expeditions::DailyDiscovery.call(
        quiz: published,
        locale: :fr,
        at: @zone.local(2098, 9, 8, 0, 0, 0),
        time_zone: "Europe/Madrid"
      )
      assert_equal "wisdom-01", discovery.id
      assert_equal Date.new(2098, 9, 8), discovery.scheduled_on
    end

    test "a guest crosses into the prepared week at Madrid midnight even while UTC is still Sunday" do
      write_schedule(state: "scheduled")
      publish(at: @zone.local(2098, 9, 2, 12))

      result = ScriptureLibraries::Screen.call(
        person: nil,
        locale: :fr,
        at: @zone.local(2098, 9, 8, 0, 0, 0)
      )

      assert_equal @unit.id, result.week.id
      assert_equal "wisdom-01", result.editorial.id
      assert_equal @starts_on, result.editorial.scheduled_on
      assert_equal "Europe/Madrid", result.editorial.time_zone
    end

    test "publication is idempotent and never creates a third version" do
      write_schedule(state: "scheduled")

      first = publish(at: @zone.local(2098, 9, 2, 12)).sole
      second = publish(at: @zone.local(2098, 9, 3, 12)).sole

      assert_equal :published, first.database_state, first.message
      assert_equal :already_published, second.database_state
      assert_equal first.quiz_version_id, second.quiz_version_id
      assert_equal 2, @unit.study_quiz_versions.count
    end

    test "an edition cannot first publish after its complete local week has expired" do
      write_schedule(state: "scheduled")

      result = publish(at: @zone.local(2098, 9, 15, 0, 0, 0)).sole

      assert result.error?
      assert_equal :expired, result.phase, result.message
      assert_includes result.message, "publication window expired"
      assert_equal @source.id, @unit.published_quiz.id
    end

    test "a standard non-expedition week accepts discoveries without invented pack ids" do
      write_schedule(state: "scheduled")

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert result.published?, result.message
      assert_empty @unit.published_quiz.expedition_pack_ids
      assert @unit.published_quiz.daily_discoveries.all? { |row| row["pack_id"].nil? }
    end

    test "a weekly edition must end with its single contemplation" do
      payload = schedule_payload(state: "scheduled")
      payload["daily_discoveries"].last["kind"] = "discovery"
      payload["expected_discoveries_digest"] =
        StudyQuizVersion.content_digest_for(payload["daily_discoveries"])
      @path.write(YAML.dump(JSON.parse(JSON.generate(payload))))

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert result.error?
      assert_includes result.message,
        "daily_discoveries must contain six discoveries followed by one contemplation"
    end

    test "a scheduled edition cannot use artwork changed after Council review" do
      payload = schedule_payload(state: "scheduled")
      payload["expected_artwork_digest"] = "0" * 64
      @path.write(YAML.dump(JSON.parse(JSON.generate(payload))))

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert result.error?
      assert_includes result.message, "daily artwork changed after Council review"
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "the delivery digests must match the canonical Council dossier" do
      write_schedule(state: "scheduled")
      dossier = YAML.safe_load_file(@dossier_path, aliases: false)
      dossier["library_editorial"]["expected_artwork_digest"] = "0" * 64
      @dossier_path.write(YAML.dump(dossier))

      result = publish(at: @zone.local(2098, 9, 2, 12)).sole

      assert result.error?
      assert_includes result.message,
        "source_dossier library_editorial artwork digest must match the delivery"
      assert_equal 1, @unit.study_quiz_versions.count
    end

    private

      def publish(at:)
        PublishScheduledDailyEditorials.call(at:, paths: [ @path ], root: @directory)
      end

      def write_schedule(state:)
        payload = schedule_payload(state:)
        @path.write(YAML.dump(JSON.parse(JSON.generate(payload))))
      end

      def schedule_payload(state:)
        discoveries = daily_discoveries
        publication = {
          "state" => state,
          "activate_at" => @zone.local(@starts_on.year, @starts_on.month, @starts_on.day).iso8601
        }
        if state == "scheduled"
          publication.merge!(
            "authorized_by" => "Test editor",
            "authorized_on" => "2098-09-02"
          )
        end

        {
          "schema_version" => 2,
          "id" => "library-2098-09-08-wisdom",
          "program_slug" => @program.slug,
          "study_unit_slug" => @unit.slug,
          "starts_on" => @starts_on.iso8601,
          "ends_on" => (@starts_on + 6.days).iso8601,
          "timezone" => "Europe/Madrid",
          "source_dossier" => @dossier_relative,
          "publication" => publication,
          "expedition_pack_ids" => [],
          "expected_discoveries_digest" => StudyQuizVersion.content_digest_for(discoveries),
          "expected_artwork_digest" => DailyEditorialSchedule.artwork_digest_for(discoveries),
          "council_review" => {
            "revision" => 1,
            "publish_ready" => true,
            "art_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "experience_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "human_dramaturgy_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "human_voice_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "truth_gate" => { "status" => "PASS", "reviewed_revision" => 1 }
          },
          "daily_discoveries" => discoveries
        }
      end

      def daily_discoveries
        artwork_contracts = [
          [ "scripture.library.daily.ps102.disappearing-voice", "ot/ps/102", %w[ot/ps/102] ],
          [ "scripture.library.daily.ps110.nameless-king", "ot/ps/110", %w[ot/ps/110] ],
          [ "scripture.library.daily.ps119.seek-me", "ot/ps/119", %w[ot/ps/119] ],
          [ "scripture.library.daily.ps127-128.house-table-city", "ot/ps/127", %w[ot/ps/127 ot/ps/128] ],
          [ "scripture.library.daily.ps137.suspended-harps", "ot/ps/137", %w[ot/ps/137] ],
          [ "scripture.library.daily.ps146-150.everything-breathes", "ot/ps/149", %w[ot/ps/146 ot/ps/147 ot/ps/148 ot/ps/149 ot/ps/150] ],
          [ "scripture.library.daily.ps102-150.weekly-contemplation", "ot/ps/102", %w[ot/ps/102 ot/ps/110 ot/ps/119 ot/ps/127 ot/ps/128 ot/ps/137 ot/ps/146 ot/ps/147 ot/ps/148 ot/ps/149 ot/ps/150] ]
        ]
        7.times.map do |index|
          number = index + 1
          artwork_key, reference, references = artwork_contracts.fetch(index)
          localized_copy = Locale::AVAILABLE.index_with do |locale|
            {
              "eyebrow" => "#{locale} today",
              "title" => "#{locale} wisdom #{number}",
              "setup" => "#{locale} a scene from wisdom literature.",
              "question" => "#{locale} what will you notice?",
              "cta_label" => "#{locale} read"
            }
          end
          localized_text = Locale::AVAILABLE.index_with { |locale| "#{locale} symbolic Proverbs artwork." }
          {
            "id" => format("wisdom-%02d", number),
            "kind" => index == 6 ? "contemplation" : "discovery",
            "status" => "approved",
            "revision" => 1,
            "scheduled_on" => (@starts_on + index.days).iso8601,
            "timezone" => "Europe/Madrid",
            "pack_id" => nil,
            "reference" => reference,
            "references" => references,
            "claim_ids" => [ "exeg-wisdom-#{number}" ],
            "artwork_key" => artwork_key,
            "light_family" => "celestial_dark",
            "depiction_mode" => "contemporary_symbolic_wisdom",
            "certainty" => { "textual" => "ATTESTÉ" },
            "motion" => "still",
            "audio" => "silent",
            "truth_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "experience_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "copy" => localized_copy,
            "alt" => localized_text,
            "disclosure" => localized_text
          }
        end
      end
  end
end
