require "test_helper"

module Studies
  class PublishQuizVersionTest < ActiveSupport::TestCase
    setup do
      @starts_on = Date.new(2045, 1, 2)
      @program = StudyProgram.create!(
        slug: "publish-quiz-#{SecureRandom.hex(6)}", title: "Programme a publier", year: 2045,
        canon: "old_testament", locale: "fr", status: "draft",
        source_url: "https://example.test/publish-quiz"
      )
      @unit = @program.study_units.create!(
        slug: "week-1", kind: "week", position: 1, title: "Psaumes",
        source_url: "https://example.test/publish-quiz/week",
        starts_on: @starts_on, ends_on: @starts_on + 6.days,
        scripture_refs: [ "Psaumes" ], status: "needs_review"
      )
      @previous = create_version(version: 1, status: "published", content: expedition_content, published_at: 1.day.ago)
      @candidate = create_version(version: 2, status: "needs_review", content: daily_content)
    end

    test "publishes and retires atomically after checking the reviewed digest" do
      at = Time.utc(2045, 1, 1, 18, 30)

      result = PublishQuizVersion.call(
        version: @candidate, expected_content_digest: @candidate.content_digest, at:
      )

      assert_equal @candidate.id, result.id
      assert_equal "published", @candidate.reload.status
      assert_equal at, @candidate.published_at
      assert_equal "retired", @previous.reload.status
      assert_equal "published", @unit.reload.status
      assert_equal "published", @program.reload.status
      assert_equal [ @candidate.id ], @unit.study_quiz_versions.where(status: "published").pluck(:id)
    end

    test "rejects a changed review digest without changing publication state" do
      assert_raises(PublishQuizVersion::Error) do
        PublishQuizVersion.call(version: @candidate, expected_content_digest: "0" * 64)
      end

      assert_equal "needs_review", @candidate.reload.status
      assert_equal "published", @previous.reload.status
      assert_equal "needs_review", @unit.reload.status
      assert_equal "draft", @program.reload.status
    end

    test "rejects stored content changed without a new digest" do
      changed = @candidate.content.deep_dup
      changed["daily_discoveries"].first["copy"]["fr"]["title"] = "Texte change apres revue"
      @candidate.update_column(:content, changed)

      error = assert_raises(PublishQuizVersion::Error) do
        PublishQuizVersion.call(
          version: @candidate, expected_content_digest: @candidate.content_digest
        )
      end

      assert_equal "stored content digest is stale", error.message
      assert_equal "needs_review", @candidate.reload.status
      assert_equal "published", @previous.reload.status
    end

    test "rolls back when one of the four localized copies is missing" do
      changed = @candidate.content.deep_dup
      changed["daily_discoveries"].first["copy"].delete("pt-BR")
      replace_candidate_content!(changed)

      error = assert_raises(PublishQuizVersion::Error) do
        PublishQuizVersion.call(
          version: @candidate, expected_content_digest: @candidate.content_digest
        )
      end

      assert_includes error.message, "must contain exactly es, pt-BR, fr, en"
      assert_equal "needs_review", @candidate.reload.status
      assert_equal "published", @previous.reload.status
      assert_equal "needs_review", @unit.reload.status
      assert_equal "draft", @program.reload.status
    end

    test "rolls back when a gate approved an older revision" do
      changed = @candidate.content.deep_dup
      changed["daily_discoveries"].first["revision"] = 2
      replace_candidate_content!(changed)

      error = assert_raises(PublishQuizVersion::Error) do
        PublishQuizVersion.call(
          version: @candidate, expected_content_digest: @candidate.content_digest
        )
      end

      assert_includes error.message, "must pass the current revision"
      assert_equal "needs_review", @candidate.reload.status
      assert_equal "published", @previous.reload.status
    end

    test "requires exactly one daily discovery for each of the seven days" do
      changed = @candidate.content.deep_dup
      changed["daily_discoveries"].pop
      replace_candidate_content!(changed)

      error = assert_raises(PublishQuizVersion::Error) do
        PublishQuizVersion.call(
          version: @candidate, expected_content_digest: @candidate.content_digest
        )
      end

      assert_includes error.message, "daily_discoveries must contain exactly 7 entries"
      assert_equal "needs_review", @candidate.reload.status
      assert_equal "published", @previous.reload.status
    end

    test "allows only the needs_review to published transition" do
      @candidate.update!(status: "draft")

      error = assert_raises(PublishQuizVersion::Error) do
        PublishQuizVersion.call(
          version: @candidate, expected_content_digest: @candidate.content_digest
        )
      end

      assert_equal "version must be needs_review", error.message
      assert_equal "published", @previous.reload.status
    end

    test "keeps a published daily payload immutable" do
      PublishQuizVersion.call(
        version: @candidate, expected_content_digest: @candidate.content_digest
      )
      changed = @candidate.reload.content.deep_dup
      changed["daily_discoveries"].first["copy"]["fr"]["title"] = "Une copie non revue"

      refute @candidate.update(content: changed)
      assert_includes @candidate.errors[:content], "published daily discoveries are immutable; publish a new version"
      assert_equal "fr titre 1", @candidate.reload.content.dig("daily_discoveries", 0, "copy", "fr", "title")
    end

    private

      def create_version(version:, status:, content:, published_at: nil)
        @unit.study_quiz_versions.create!(
          version:, status:, editorial_locale: "fr", content:,
          content_digest: Digest::SHA256.hexdigest(content.to_json), published_at:
        )
      end

      def replace_candidate_content!(content)
        digest = Digest::SHA256.hexdigest(content.to_json)
        @candidate.update!(content:, content_digest: digest)
      end

      def expedition_content
        {
          "questions" => [],
          "readings" => [],
          "expedition" => {
            "id" => "previous-expedition",
            "pack_ids" => [ "exp_psalms_disappearing_voice" ]
          }
        }
      end

      def daily_content
        expedition_content.merge(
          "daily_discoveries" => 7.times.map { |index| discovery(index) }
        )
      end

      def discovery(index)
        number = index + 1
        {
          "id" => format("daily-%02d", number),
          "kind" => index == 6 ? "contemplation" : "discovery",
          "revision" => 1,
          "scheduled_on" => (@starts_on + index.days).iso8601,
          "timezone" => "Europe/Madrid",
          "status" => "approved",
          "pack_id" => index == 6 ? nil : "exp_psalms_disappearing_voice",
          "reference" => "ot/ps/137",
          "references" => [ "ot/ps/137" ],
          "claim_ids" => [ format("exeg-%03d", number) ],
          "depiction_mode" => "symbolic_atmosphere",
          "certainty" => "ATTESTE",
          "artwork_key" => "scripture.library.daily.#{number}",
          "light_family" => "celestial_dark",
          "motion" => "still",
          "audio" => "silent",
          "truth_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
          "experience_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
          "copy" => localized_copy(number),
          "alt" => localized_text("Illustration", number),
          "disclosure" => localized_text("Illustration dramatisee", number)
        }
      end

      def localized_copy(number)
        Locale::AVAILABLE.index_with do |locale|
          {
            "eyebrow" => "#{locale} aujourd'hui #{number}",
            "title" => "#{locale} titre #{number}",
            "setup" => "#{locale} contexte #{number}",
            "question" => "#{locale} question #{number}",
            "cta_label" => "#{locale} ouvrir #{number}"
          }
        end
      end

      def localized_text(prefix, number)
        Locale::AVAILABLE.index_with { |locale| "#{prefix} #{locale} #{number}" }
      end
  end
end
