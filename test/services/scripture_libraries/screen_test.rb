require "test_helper"

module ScriptureLibraries
  class ScreenTest < ActiveSupport::TestCase
    setup do
      @zone = Time.find_zone!("Europe/Madrid")
      @starts_on = Date.new(2199, 8, 26).beginning_of_week
      @at = @zone.local(@starts_on.year, @starts_on.month, @starts_on.day, 12)
      @ward = wards(:demo)
      @ward.update!(scripture_circle_mode: "active", time_zone: @zone.name)
      @person = Person.create!(
        ward: @ward,
        given_name: "Library#{SecureRandom.hex(3)}",
        avatar_key: Player::AVATARS.first,
        locale: "fr"
      )
      @week, @quiz = create_published_week
    end

    test "omits personal sections when their underlying facts do not exist" do
      result = screen(person: nil)

      assert result.editorial
      assert_nil result.resume
      assert_nil result.quiz_prompt
      assert_empty result.rama_highlights
      assert result.week
      assert_equal 0, result.week.reading_completed_count
      assert_equal 2, result.week.reading_total_count
      assert_equal 0.0, result.week.reading_progress
      assert_nil result.tools.bookmarks
      assert_equal 0, result.tools.scriptures.count
      assert result.tools.annual
    end

    test "uses the approved quiz timezone for a guest across the UTC week boundary" do
      local_time = @zone.local(
        @starts_on.year,
        @starts_on.month,
        @starts_on.day,
        0,
        30
      )

      result = Screen.call(person: nil, locale: :fr, at: local_time.utc)

      assert_equal @week.id, result.week.id
      assert_equal @starts_on, result.editorial.scheduled_on
      assert_equal @zone.name, result.editorial.time_zone
      assert_equal "daily-0", result.editorial.id
    end

    test "only exposes the bookmark recovery tool when a bookmark exists" do
      @person.scripture_marks.create!(
        reference: "ot/ps/137",
        locale: "fr",
        anchor_scope: "passage",
        visual_style: "none",
        start_verse: 1,
        start_offset: 0,
        end_verse: 1,
        end_offset: 12,
        selected_text: "Au bord des fleuves",
        bookmarked_at: @at - 1.hour
      )

      bookmarks = screen.tools.bookmarks

      assert_equal 1, bookmarks.count
      assert_includes bookmarks.detail, "Psaumes 137:1"
      assert_equal "bookmarks", Rack::Utils.parse_nested_query(URI.parse(bookmarks.path).query).fetch("section")
    end

    test "resume is selected in SQL from the newest genuinely resumable chapter" do
      resumable = reading_progress(
        reference: "ot/ps/102",
        ratio: 0.42,
        verse: 7,
        opened_at: @at - 3.hours
      )
      reading_progress(
        reference: "ot/ps/110",
        ratio: 0.07,
        verse: 4,
        opened_at: @at - 1.hour
      )
      reading_progress(
        reference: "ot/ps/119",
        ratio: 0.9,
        verse: 150,
        opened_at: @at,
        completed_at: @at
      )

      result = screen

      assert_equal resumable.reference, result.resume.reference
      assert_equal resumable.last_verse, result.resume.last_verse
      assert_equal resumable.progress_ratio.to_f, result.resume.progress
      assert_equal "/escrituras/ot/ps/102", URI.parse(result.resume.path).path
    end

    test "week keeps reading and expedition progress as two distinct measures" do
      reading_progress(
        reference: "ot/ps/102",
        ratio: 1.0,
        verse: 28,
        opened_at: @at - 1.day,
        completed_at: @at - 1.day
      )
      reading_progress(
        reference: "ot/ps/110",
        ratio: 0.4,
        verse: 4,
        opened_at: @at - 1.hour
      )
      QuizRun.create!(
        person: @person,
        device_digest: Digest::SHA256.hexdigest("library-week-finished"),
        pack_id: "exp_psalms_disappearing_voice",
        position: 10,
        score: 75,
        status: "finished",
        opened_at: @at - 1.day
      )

      week = screen.week

      assert_equal 1, week.reading_completed_count
      assert_equal 2, week.reading_total_count
      assert_equal 0.5, week.reading_progress
      assert_equal 1, week.expedition_completed_count
      assert_equal 2, week.expedition_total_count
      assert_equal 0.5, week.expedition_progress
      assert_equal "Deux portes", week.expedition_title
      assert_equal "Ouvre les Psaumes.", week.expedition_promise
      assert_equal "/mapa", URI.parse(week.expedition_path).path
      refute_respond_to week, :progress
    end

    test "wraps the approved daily discovery with a localized reader route" do
      discovery = Expeditions::DailyDiscovery::Result.new(
        id: "daily-psalm-110",
        kind: "discovery",
        scheduled_on: @starts_on,
        time_zone: @zone.name,
        locale: "fr",
        pack_id: "exp_psalms_nameless_king",
        reference: "ot/ps/110",
        references: %w[ot/ps/110 ot/ps/102],
        claim_ids: [ "exeg-004" ],
        eyebrow: "Aujourd'hui dans les Ecritures",
        title: "Un roi devient pretre.",
        setup: "Le poeme reunit deux roles.",
        question: "Pourquoi Melchisedek apparait-il ici ?",
        cta_label: "Entrer dans le mystere",
        artwork_key: "scripture.library.daily.psalm-110",
        light_family: "celestial_dark",
        depiction_mode: "symbolic_atmosphere",
        certainty: "DISCUTE",
        disclosure: "Illustration dramatisee.",
        alt: "Une couronne et une lampe.",
        motion: "still",
        audio: "silent"
      )
      received = nil
      resolver = lambda do |**arguments|
        received = arguments
        discovery
      end

      original = Expeditions::DailyDiscovery.method(:call)
      Expeditions::DailyDiscovery.define_singleton_method(:call, &resolver)
      result = screen

      assert_equal @quiz, received.fetch(:quiz)
      assert_equal :fr, received.fetch(:locale)
      assert_equal @zone.name, received.fetch(:time_zone)
      assert_equal @at, received.fetch(:at)
      assert_equal "exp_psalms_nameless_king", result.editorial.pack_id
      assert_equal %w[ot/ps/110 ot/ps/102], result.editorial.references
      assert_equal "Psaumes 110", result.editorial.cite
      assert_equal "/escrituras/ot/ps/110", URI.parse(result.editorial.path).path
      assert_equal "fr", Rack::Utils.parse_nested_query(URI.parse(result.editorial.path).query).fetch("locale")
      assert result.editorial.reader?
      assert_equal "symbolic_atmosphere", result.editorial.depiction_mode
      assert_equal "DISCUTE", result.editorial.certainty
    ensure
      Expeditions::DailyDiscovery.define_singleton_method(:call, original) if original
    end

    test "routes the seventh-day contemplation to the merged weekly destination" do
      discovery = Expeditions::DailyDiscovery::Result.new(
        id: "daily-week-contemplation",
        kind: "contemplation",
        scheduled_on: @starts_on + 6.days,
        time_zone: @zone.name,
        locale: "fr",
        pack_id: nil,
        reference: "ot/ps/150",
        references: %w[ot/ps/150 ot/ps/102 ot/ps/119],
        claim_ids: [ "exeg-week" ],
        eyebrow: "Cette semaine dans les Ecritures",
        title: "Six portes restent ouvertes.",
        setup: "Reviens sur ce qui t'a retenu.",
        question: "Qu'est-ce que tu n'avais jamais remarque ?",
        cta_label: "Contempler la semaine",
        artwork_key: "scripture.library.daily.week",
        light_family: "celestial_dark",
        depiction_mode: "symbolic_atmosphere",
        certainty: "SYMBOLIQUE",
        disclosure: "Composition symbolique.",
        alt: "Six fenetres distinctes.",
        motion: "still",
        audio: "silent"
      )
      original = Expeditions::DailyDiscovery.method(:call)
      Expeditions::DailyDiscovery.define_singleton_method(:call) { |**| discovery }

      result = Screen.call(
        person: @person,
        locale: :fr,
        at: @zone.local(2199, 9, 1, 12),
        time_zone: @zone.name
      )

      refute result.editorial.reader?
      assert_nil result.editorial.pack_id
      assert_equal "Psaumes 102–150", result.editorial.cite
      query = Rack::Utils.parse_nested_query(URI.parse(result.editorial.path).query)
      assert_equal "weekly", query.fetch("section")
      assert_equal @week.id.to_s, query.fetch("unit")
      assert_equal "cette-semaine", URI.parse(result.editorial.path).fragment
    ensure
      Expeditions::DailyDiscovery.define_singleton_method(:call, original) if original
    end

    test "does not invent a current week outside the published dates" do
      result = Screen.call(
        person: @person,
        locale: :fr,
        at: @zone.local(2199, 9, 30, 12),
        time_zone: @zone.name
      )

      assert_nil result.editorial
      assert_nil result.week
      assert result.tools.annual
    end

    private

      def screen(person: @person)
        Screen.call(person:, locale: :fr, at: @at, time_zone: @zone.name)
      end

      def create_published_week
        program = StudyProgram.create!(
          slug: "library-screen-#{SecureRandom.hex(6)}",
          title: "Programme Bibliotheque",
          year: 2199,
          canon: "old_testament",
          locale: "fr",
          status: "published",
          source_url: "https://example.test/library-screen"
        )
        week = program.study_units.create!(
          slug: "week-1",
          kind: "week",
          position: 1,
          title: "Psaumes 102-110",
          source_url: "https://example.test/library-screen/week",
          starts_on: @starts_on,
          ends_on: @starts_on + 6.days,
          scripture_refs: [ "Psaumes 102-110" ],
          copy: {
            "fr" => {
              "title" => "26 aout - 1 septembre : Psaumes 102-110",
              "theme" => "Quand il ne reste que la foi",
              "scripture_refs" => [ "Psaumes 102-110" ]
            }
          },
          status: "published"
        )
        content = {
          "questions" => [],
          "readings" => [
            { "study" => "ot/ps/102", "labels" => { "fr" => "Psaume 102" } },
            { "study" => "ot/ps/110", "labels" => { "fr" => "Psaume 110" } }
          ],
          "expedition" => {
            "id" => "library-two-doors",
            "title" => { "fr" => "Deux portes" },
            "promise" => { "fr" => "Ouvre les Psaumes." },
            "pack_ids" => [
              "exp_psalms_disappearing_voice",
              "exp_psalms_nameless_king"
            ]
          },
          "daily_discoveries" => daily_discoveries
        }
        quiz = week.study_quiz_versions.create!(
          version: 1,
          status: "published",
          editorial_locale: "fr",
          content:,
          content_digest: Digest::SHA256.hexdigest(content.to_json),
          published_at: @at - 1.day
        )
        [ week, quiz ]
      end

      def daily_discoveries
        7.times.map do |offset|
          copy = Locale::AVAILABLE.index_with do |_locale|
            {
              "eyebrow" => "Aujourd'hui dans les Ecritures",
              "title" => "Une porte #{offset + 1}",
              "setup" => "Une scène exacte du psaume.",
              "question" => "Qu'allons-nous remarquer aujourd'hui ?",
              "cta_label" => "Découvrir"
            }
          end
          localized = Locale::AVAILABLE.index_with { |locale| "Description #{locale}." }

          {
            "id" => "daily-#{offset}",
            "kind" => offset == 6 ? "contemplation" : "discovery",
            "status" => "approved",
            "scheduled_on" => (@starts_on + offset.days).iso8601,
            "timezone" => @zone.name,
            "pack_id" => offset == 6 ? nil : (offset.even? ? "exp_psalms_disappearing_voice" : "exp_psalms_nameless_king"),
            "reference" => offset.even? ? "ot/ps/102" : "ot/ps/110",
            "references" => [ offset.even? ? "ot/ps/102" : "ot/ps/110" ],
            "claim_ids" => [ "claim-#{offset}" ],
            "artwork_key" => "scripture.library.daily.#{offset}",
            "light_family" => "celestial_dark",
            "depiction_mode" => "symbolic_atmosphere",
            "certainty" => "ETABLI",
            "revision" => 1,
            "truth_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "experience_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "copy" => copy,
            "alt" => localized,
            "disclosure" => localized,
            "motion" => "still",
            "audio" => "silent"
          }
        end
      end

      def reading_progress(reference:, ratio:, verse:, opened_at:, completed_at: nil)
        @person.scripture_reading_progresses.create!(
          reference:,
          locale: "fr",
          first_opened_at: opened_at - 1.hour,
          last_opened_at: opened_at,
          last_verse: verse,
          progress_ratio: ratio,
          completed_at:
        )
      end
  end
end
