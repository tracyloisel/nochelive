require "test_helper"

module Expeditions
  class DailyDiscoveryTest < ActiveSupport::TestCase
    setup do
      @starts_on = Date.new(2044, 8, 29)
      program = StudyProgram.create!(
        slug: "daily-discovery-#{SecureRandom.hex(6)}", title: "Programme quotidien", year: 2044,
        canon: "old_testament", locale: "fr", status: "published",
        source_url: "https://example.test/daily-discovery"
      )
      @unit = program.study_units.create!(
        slug: "week-1", kind: "week", position: 1, title: "Psaumes",
        source_url: "https://example.test/daily-discovery/week",
        starts_on: @starts_on, ends_on: @starts_on + 6.days,
        scripture_refs: [ "Psaumes" ], status: "published"
      )
      @quiz = create_version(status: "published", published_at: Time.utc(2044, 8, 28, 12))
    end

    test "resolves the one approved discovery for the exact local date and locale" do
      at = Time.utc(2044, 8, 30, 22, 30) # 31 August in Europe/Madrid

      result = DailyDiscovery.call(quiz: @quiz, locale: :fr, at:, time_zone: "Europe/Madrid")

      assert_equal "daily-03", result.id
      assert_equal Date.new(2044, 8, 31), result.scheduled_on
      assert_equal "fr titre 3", result.title
      assert_equal "fr question 3", result.question
      assert_equal "ot/ps/102", result.reference
      assert_equal "exp_psalms_suspended_harps", result.pack_id
      assert_equal [ "ot/ps/102" ], result.references
      assert_equal [ "exeg-003" ], result.claim_ids
      assert_equal "Illustration fr 3", result.alt
      assert_equal "Europe/Madrid", result.time_zone
    end

    test "resolves the seventh contemplation then returns nil outside the dated week" do
      zone = Time.find_zone!("Europe/Madrid")

      seventh = DailyDiscovery.call(
        quiz: @quiz, locale: :fr, at: zone.local(2044, 9, 4, 12), time_zone: "Europe/Madrid"
      )
      assert_equal "daily-07", seventh.id
      assert_equal "contemplation", seventh.kind
      assert_nil seventh.pack_id

      assert_nil DailyDiscovery.call(
        quiz: @quiz, locale: :fr, at: zone.local(2044, 9, 5, 12), time_zone: "Europe/Madrid"
      )
    end

    test "requires the caller's explicit timezone to match the approved schedule" do
      at = Time.find_zone!("Europe/Madrid").local(2044, 8, 29, 12)

      assert_nil DailyDiscovery.call(quiz: @quiz, locale: :fr, at:, time_zone: "UTC")
      assert_nil DailyDiscovery.call(quiz: @quiz, locale: :fr, at:, time_zone: nil)
    end

    test "fails closed when a locale or approval is missing" do
      missing_locale = @quiz.content.deep_dup
      missing_locale["daily_discoveries"].first["copy"].delete("en")
      replace_content!(missing_locale)

      assert_nil resolved_first_day

      unapproved = version_content
      unapproved["daily_discoveries"].first["truth_gate"]["status"] = "REJECT"
      replace_content!(unapproved)

      assert_nil resolved_first_day
    end

    test "fails closed when its expedition pack or scripture route is not approved" do
      wrong_pack = version_content
      wrong_pack["daily_discoveries"].first["pack_id"] = "invented-pack"
      replace_content!(wrong_pack)

      assert_nil resolved_first_day

      wrong_route = version_content
      wrong_route["daily_discoveries"].first["references"] = [ "ot/ps/110" ]
      replace_content!(wrong_route)

      assert_nil resolved_first_day
    end

    test "fails closed for unpublished future or digest-stale sources" do
      @quiz.update_column(:published_at, Time.utc(2045, 1, 1))
      assert_nil resolved_first_day

      @quiz.update_column(:published_at, Time.utc(2044, 8, 28, 12))
      changed = @quiz.content.deep_dup
      changed["daily_discoveries"].first["copy"]["fr"]["title"] = "Texte non revu"
      @quiz.update_column(:content, changed)

      assert_nil resolved_first_day
    end

    test "does not fall back from an unsupported locale" do
      at = Time.find_zone!("Europe/Madrid").local(2044, 8, 29, 12)

      assert_nil DailyDiscovery.call(quiz: @quiz, locale: :de, at:, time_zone: "Europe/Madrid")
    end

    private

      def resolved_first_day
        at = Time.find_zone!("Europe/Madrid").local(2044, 8, 29, 12)
        DailyDiscovery.call(quiz: @quiz.reload, locale: :fr, at:, time_zone: "Europe/Madrid")
      end

      def create_version(status:, published_at: nil)
        content = version_content
        @unit.study_quiz_versions.create!(
          version: 1, status:, editorial_locale: "fr", content:,
          content_digest: Digest::SHA256.hexdigest(content.to_json), published_at:
        )
      end

      def replace_content!(content)
        @quiz.update_columns(content:, content_digest: StudyQuizVersion.content_digest_for(content))
      end

      def version_content
        {
          "questions" => [],
          "readings" => [],
          "expedition" => {
            "id" => "daily-psalms",
            "pack_ids" => [ "exp_psalms_suspended_harps" ]
          },
          "daily_discoveries" => 7.times.map { |index| discovery(index) }
        }
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
          "pack_id" => index == 6 ? nil : "exp_psalms_suspended_harps",
          "reference" => "ot/ps/102",
          "references" => [ "ot/ps/102" ],
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
