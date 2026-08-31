require "test_helper"

unless defined?(Seeds::ScriptureCircleDemo)
  previous_definition_only = ENV["SCRIPTURE_CIRCLE_DEMO_DEFINITION_ONLY"]
  ENV["SCRIPTURE_CIRCLE_DEMO_DEFINITION_ONLY"] = "1"
  load Rails.root.join("db/seeds/scripture_circle_demo.rb")
  previous_definition_only.nil? ? ENV.delete("SCRIPTURE_CIRCLE_DEMO_DEFINITION_ONLY") : ENV["SCRIPTURE_CIRCLE_DEMO_DEFINITION_ONLY"] = previous_definition_only
end

class Seeds::ScriptureCircleDemoTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @target = people(:carmen_garcia)
    @ward = @target.ward
  end

  test "is idempotent and preserves the target ward preferences progress and unrelated publication" do
    original_ward_id = @target.ward_id
    preference = @target.create_scripture_reader_preference!(font_scale: 130)
    progress = Scriptures::ReadingProgress::Record.call(
      person: @target, reference: "ot/ps/52", locale: "fr",
      last_verse: 8, progress_ratio: 0.8, at: 2.days.ago
    )
    thread = @ward.scripture_circle_threads.create!(reference: "ot/ps/52")
    unrelated = thread.scripture_circle_posts.create!(
      ward: @ward, person: @target, kind: "reflection", locale: "fr",
      body: "Une vraie publication qui ne vient pas de la démonstration."
    )

    first = Seeds::ScriptureCircleDemo.new(target: @target, now: Time.zone.parse("2026-08-30 10:00:00")).call
    counts = demo_counts
    second = Seeds::ScriptureCircleDemo.new(target: @target, now: Time.zone.parse("2026-08-30 10:00:00")).call

    assert_equal counts, demo_counts
    assert_equal original_ward_id, @target.reload.ward_id
    assert_equal 130, preference.reload.font_scale
    assert_equal 8, progress.reload.last_verse
    assert_equal 0.8, progress.progress_ratio.to_f
    assert_equal "Une vraie publication qui ne vient pas de la démonstration.", unrelated.reload.body
    assert_equal 12, first[:posts] - 1
    assert_equal 11, first[:showcase_posts]
    assert_equal first[:posts], second[:posts]
    assert_equal first[:showcase_posts], second[:showcase_posts]
    assert_equal 1, second[:open_votes]
  end

  test "adds a visible multichapter showcase for every Circle filter" do
    result = Seeds::ScriptureCircleDemo.new(target: @target, now: Time.zone.parse("2026-08-30 10:00:00")).call
    screens = %w[help recent mine].map do |view|
      ScriptureCircles::RamaScreen.call(person: @target, locale: "fr", view:)
    end
    cards = screens.flat_map(&:conversations).index_by(&:root_id).values

    assert_equal 11, result[:showcase_posts]
    assert_equal 3, screens.first.help_count
    assert_equal %w[bofm/alma/32 bofm/alma/7 bofm/2-ne/2 bofm/mosiah/2 ot/ps/52].sort,
      cards.map { |card| card.chapter.reference }.uniq.sort
    assert_equal 2, cards.count { |card| card.chapter.reference == "bofm/alma/32" }
    assert cards.any? { |card| card.root.anonymous? }
    assert_equal "anonymous_to_ward", @ward.scripture_circle_posts.find_by!(selected_text: "#{Seeds::ScriptureCircleDemo::SHOWCASE_MARKER_PREFIX}alma-anonymous-question").author_visibility
  end

  test "fails clearly for a profile without a ward" do
    person = Person.create!(given_name: "Sans paroisse", avatar_key: "delfin", locale: "fr")

    error = assert_raises(ArgumentError) { Seeds::ScriptureCircleDemo.new(target: person) }

    assert_match(/ward/, error.message)
  end

  test "refuses production before writing" do
    seed = Seeds::ScriptureCircleDemo.new(target: @target, environment: "production")

    assert_raises(RuntimeError) { seed.call }
    assert_not @ward.reload.scripture_circle_active?
  end

  test "does not touch another ward thread or posts" do
    other_ward = extra_ward(67, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Hors périmètre", avatar_key: "delfin", locale: "fr")
    other_thread = other_ward.scripture_circle_threads.create!(reference: "ot/ps/52")
    other_post = other_thread.scripture_circle_posts.create!(
      ward: other_ward, person: outsider, kind: "question", locale: "fr", body: "Question extérieure intacte"
    )

    Seeds::ScriptureCircleDemo.new(target: @target).call

    assert_equal 1, other_thread.scripture_circle_posts.count
    assert_equal "Question extérieure intacte", other_post.reload.body
    assert_equal other_ward.id, other_post.ward_id
  end

  private

    def demo_counts
      {
        people: @ward.people.where(family_name: "Démo").count,
        posts: @ward.scripture_circle_posts.where("selected_text LIKE ?", "scripture-reader-demo-v1:%").count,
        proposals: ScriptureCircleModerationProposal.where(ward: @ward).count,
        ballots: ScriptureCircleModerationBallot.where(ward: @ward).count,
        marks: @target.scripture_marks.where("source_digest IS NOT NULL").count
      }
    end
end
