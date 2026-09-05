require "test_helper"

module Studies
  class PublishDailyDiscoveriesTest < ActiveSupport::TestCase
    setup do
      @starts_on = Date.new(2046, 8, 31)
      @program = StudyProgram.create!(
        slug: "daily-edition-#{SecureRandom.hex(6)}",
        title: "Edition quotidienne",
        year: 2046,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/daily-edition"
      )
      @unit = @program.study_units.create!(
        slug: "psalms-week",
        kind: "week",
        position: 1,
        title: "Psaumes 102-150",
        source_url: "https://example.test/daily-edition/week",
        starts_on: @starts_on,
        ends_on: @starts_on + 6.days,
        scripture_refs: [ "Psaumes 102-150" ],
        status: "published"
      )
      @source = @unit.study_quiz_versions.create!(
        version: 3,
        status: "published",
        editorial_locale: "fr",
        content: expedition_content,
        content_digest: StudyQuizVersion.content_digest_for(expedition_content),
        published_at: 1.day.ago
      )
      @discoveries = daily_discoveries
      @reviewed_digest = StudyQuizVersion.content_digest_for(@discoveries)
    end

    test "publishes a new immutable version and preserves the prior payload" do
      published = publish(at: Time.utc(2046, 8, 30, 18, 0))

      assert_equal 4, published.version
      assert_equal "published", published.status
      assert_equal @discoveries, published.daily_discoveries
      assert_equal "retired", @source.reload.status
      refute @source.content.key?("daily_discoveries")
      assert published.content_digest_current?
    end

    test "is idempotent once the reviewed schedule is already published" do
      first = publish
      second = publish

      assert_equal first.id, second.id
      assert_equal 2, @unit.study_quiz_versions.count
      assert_equal 1, @unit.study_quiz_versions.where(status: "published").count
    end

    test "rejects copy changed after the council review" do
      @discoveries.first["copy"]["fr"]["title"] = "Titre modifie"

      error = assert_raises(PublishDailyDiscoveries::Error) { publish }

      assert_equal "daily discoveries changed after review", error.message
      assert_equal "published", @source.reload.status
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "rolls back an invalid seven-day publication" do
      @discoveries.last["pack_id"] = "invented-pack"
      @reviewed_digest = StudyQuizVersion.content_digest_for(@discoveries)

      error = assert_raises(PublishDailyDiscoveries::Error) { publish }

      assert_includes error.message, "pack_id must belong to the expedition"
      assert_equal "published", @source.reload.status
      assert_equal 1, @unit.study_quiz_versions.count
    end

    test "does not replace another candidate already awaiting review" do
      @unit.study_quiz_versions.create!(
        version: 4,
        status: "needs_review",
        editorial_locale: "fr",
        content: expedition_content.merge("draft_note" => "other work"),
        content_digest: StudyQuizVersion.content_digest_for(expedition_content.merge("draft_note" => "other work"))
      )

      error = assert_raises(PublishDailyDiscoveries::Error) { publish }

      assert_equal "study unit already has a different version in review", error.message
      assert_equal "published", @source.reload.status
    end

    private

      def publish(at: Time.current)
        PublishDailyDiscoveries.call(
          study_unit: @unit,
          discoveries: @discoveries,
          expected_discoveries_digest: @reviewed_digest,
          at:
        )
      end

      def expedition_content
        {
          "questions" => [],
          "readings" => [],
          "expedition" => {
            "id" => "psalms-daily-edition",
            "pack_ids" => [ "psalms_living_god" ],
            "rama_hero" => {
              "revision" => 1,
              "headline" => Locale::AVAILABLE.index_with { |locale| "Rama headline #{locale}" },
              "artwork_key" => "expedition.psalms-102-150-fast.rama-weekly-hero",
              "artwork_digest" => Expeditions::RamaHero.artwork_digest_for("expedition.psalms-102-150-fast.rama-weekly-hero"),
              "light_family" => "celestial_light"
            }
          }
        }
      end

      def daily_discoveries
        7.times.map do |index|
          localized_copy = Locale::AVAILABLE.index_with do |locale|
            {
              "eyebrow" => "#{locale} aujourd'hui",
              "title" => "#{locale} porte #{index + 1}",
              "setup" => "#{locale} une scene du psaume.",
              "question" => "#{locale} que remarques-tu ?",
              "cta_label" => "#{locale} decouvrir"
            }
          end
          localized_text = Locale::AVAILABLE.index_with { |locale| "#{locale} illustration." }

          {
            "id" => "daily-#{index + 1}",
            "kind" => index == 6 ? "contemplation" : "discovery",
            "revision" => 1,
            "scheduled_on" => (@starts_on + index.days).iso8601,
            "timezone" => "Europe/Madrid",
            "status" => "approved",
            "pack_id" => index == 6 ? nil : "psalms_living_god",
            "reference" => "ot/ps/102",
            "references" => [ "ot/ps/102" ],
            "claim_ids" => [ "claim-#{index + 1}" ],
            "depiction_mode" => "symbolic_atmosphere",
            "certainty" => "ATTESTE",
            "artwork_key" => "scripture.library.daily.#{index + 1}",
            "light_family" => "celestial_dark",
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
