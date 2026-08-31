require "test_helper"

module ScriptureLibraries
  class SelectionTest < ActiveSupport::TestCase
    test "preview weekly choices all open the reader" do
      selection = select(section: "weekly", unit: "preview", preview: true)

      assert_equal :weekly, selection.key
      assert_operator selection.items.size, :>=, 3
      assert selection.items.all?(&:reader)
      assert selection.items.all? { |item| item.path.start_with?("/escrituras/") }
      assert selection.items.all? { |item| query(item.path).fetch("locale") == "fr" }
      refute selection.items.any? { |item| item.path == Rails.application.routes.url_helpers.scripture_library_path }
    end

    test "the canonical drill down ends in reader chapters instead of public seo pages" do
      collections = select(section: "canon")
      assert_equal :collection, collections.key
      assert_equal %w[old_testament new_testament book_of_mormon doctrine_and_covenants],
        collections.items.map { |item| query(item.path).fetch("collection") }

      books = select(section: "canon", collection: "old_testament")
      psalms = books.items.find { |item| query(item.path)["book"] == "ot/ps" }
      assert psalms, "the Old Testament chooser should contain Psalms"
      refute psalms.reader

      chapters = select(section: "canon", collection: "old_testament", book: "ot/ps")
      assert_equal 150, chapters.items.size
      assert chapters.items.all?(&:reader)
      assert_equal "/escrituras/ot/ps/1", URI.parse(chapters.items.first.path).path
      assert chapters.items.all? { |item| query(item.path).fetch("locale") == "fr" }
      refute chapters.items.any? { |item| URI.parse(item.path).path.start_with?("/fr/bible/") }
    end

    test "bookmarks contain only the signed in reader's real saved passages" do
      person = people(:pili)
      own_mark = bookmark(person:, reference: "ot/1-sam/16", verse: 13, text: "Samuel prit la corne d’huile")
      bookmark(person: people(:carmen_garcia), reference: "nt/john/3", verse: 16, text: "Dieu a tant aimé")

      selection = select(section: "bookmarks", person:)

      assert_equal :bookmarks, selection.key
      assert_equal 1, selection.items.size
      item = selection.items.first
      assert item.reader
      assert_equal "1 Samuel 16:13", item.title
      assert_equal own_mark.selected_text, item.detail
      assert_equal "/escrituras/ot/1-sam/16", URI.parse(item.path).path
      assert_equal "fr", query(item.path).fetch("locale")
    end

    test "bookmark pages carry a cursor instead of repeating the first twelve passages" do
      person = people(:pili)
      13.times do |index|
        bookmark(
          person:, reference: "ot/1-sam/16", verse: index + 1,
          text: "Passage sauvegardé #{index + 1}", at: Time.current - index.minutes
        )
      end

      first_page = select(section: "bookmarks", person:)
      assert_equal 13, first_page.items.size
      assert_equal :pagination, first_page.items.last.kind
      refute first_page.items.last.reader

      cursor = query(first_page.items.last.path).fetch("cursor")
      second_page = select(section: "bookmarks", person:, cursor:)
      assert_equal 1, second_page.items.size
      assert second_page.items.first.reader
      refute_includes first_page.items.first(12).map(&:title), second_page.items.first.title
    end

    test "the annual programme drills through a published week into its readings" do
      week = published_week

      programme = select(section: "program")
      assert_equal :annual, programme.key
      assert_equal [ week.id.to_s ], programme.items.map { |item| query(item.path).fetch("unit") }
      refute programme.items.first.reader

      readings = select(section: "program", unit: week.id)
      assert_operator readings.items.size, :>=, 3
      assert readings.items.all?(&:reader)
      assert readings.items.all? { |item| query(item.path).fetch("study_unit_id") == week.id.to_s }
      assert readings.items.all? { |item| query(item.path).fetch("locale") == "fr" }
    end

    test "the weekly chooser exposes readings and expedition as separate progressions" do
      person = Person.create!(
        ward: wards(:demo), given_name: "Weekly#{SecureRandom.hex(3)}",
        avatar_key: Player::AVATARS.first, locale: "fr"
      )
      week = published_expedition_week
      person.scripture_reading_progresses.create!(
        reference: "ot/ps/102", locale: "fr",
        first_opened_at: 2.hours.ago, last_opened_at: 1.hour.ago,
        last_verse: 28, progress_ratio: 1.0, completed_at: 1.hour.ago
      )
      QuizRun.create!(
        person:, device_digest: Digest::SHA256.hexdigest("selection-expedition"),
        pack_id: "exp_psalms_disappearing_voice", position: 10, score: 70,
        status: "finished", opened_at: Time.current
      )

      selection = select(section: "weekly", unit: week.id, person:)
      feature = selection.feature

      assert_equal week.id, feature.week_id
      assert_equal 1, feature.reading_completed_count
      assert_equal 2, feature.reading_total_count
      assert_equal 0.5, feature.reading_progress
      assert_equal 1, feature.expedition_completed_count
      assert_equal 2, feature.expedition_total_count
      assert_equal 0.5, feature.expedition_progress
      assert_equal "Deux portes", feature.expedition_title
      assert_equal "/mapa", URI.parse(feature.expedition_path).path
      refute_respond_to feature, :progress
    end

    test "unknown sections and unpublished week ids cannot create a hidden destination" do
      draft_week = published_week(status: "draft")

      assert_nil select(section: "javascript:alert(1)")
      selection = select(section: "program", unit: draft_week.id)
      assert selection.items.none? { |item| item.path.include?("study_unit_id=#{draft_week.id}") }
    end

    private

      def select(section:, person: nil, locale: :fr, preview: false, **options)
        ScriptureLibraries::Selection.call(person:, locale:, section:, preview:, **options)
      end

      def query(path)
        Rack::Utils.parse_nested_query(URI.parse(path).query)
      end

      def bookmark(person:, reference:, verse:, text:, at: Time.current)
        person.scripture_marks.create!(
          reference:, locale: "fr", anchor_scope: "passage", visual_style: "none",
          start_verse: verse, start_offset: 0, end_verse: verse, end_offset: 8,
          selected_text: text, bookmarked_at: at
        )
      end

      def published_week(status: "published")
        program = StudyProgram.create!(
          slug: "library-program-#{status}", title: "Viens et suis-moi", year: status == "published" ? 2098 : 2097,
          canon: "old_testament", locale: "fr", status:, source_url: "https://example.test/library-program"
        )
        week = program.study_units.create!(
          slug: "library-week-#{status}", kind: "week", position: 1, title: "Psaumes 49–51",
          source_url: "https://example.test/library-week", starts_on: Date.current.beginning_of_week,
          ends_on: Date.current.end_of_week, scripture_refs: [ "Psaumes 49–51" ], status:
        )
        content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml")).dig("quizzes", 0, "content")
        week.study_quiz_versions.create!(
          version: 1, status:, editorial_locale: "fr", content:,
          content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: (Time.current if status == "published")
        )
        week
      end

      def published_expedition_week
        program = StudyProgram.create!(
          slug: "library-expedition-#{SecureRandom.hex(5)}", title: "Viens et suis-moi", year: 2096,
          canon: "old_testament", locale: "fr", status: "published",
          source_url: "https://example.test/library-expedition"
        )
        week = program.study_units.create!(
          slug: "library-expedition-week", kind: "week", position: 1, title: "Psaumes 102-110",
          source_url: "https://example.test/library-expedition/week",
          starts_on: Date.current.beginning_of_week, ends_on: Date.current.end_of_week,
          scripture_refs: [ "Psaumes 102-110" ], status: "published"
        )
        content = {
          "questions" => [],
          "readings" => [
            { "study" => "ot/ps/102", "labels" => { "fr" => "Psaume 102" } },
            { "study" => "ot/ps/110", "labels" => { "fr" => "Psaume 110" } }
          ],
          "expedition" => {
            "id" => "selection-two-doors",
            "title" => { "fr" => "Deux portes" },
            "promise" => { "fr" => "Ouvre les Psaumes." },
            "pack_ids" => [ "exp_psalms_disappearing_voice", "exp_psalms_nameless_king" ]
          }
        }
        week.study_quiz_versions.create!(
          version: 1, status: "published", editorial_locale: "fr", content:,
          content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
        )
        week
      end
  end
end
