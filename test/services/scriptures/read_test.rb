require "test_helper"

class Scriptures::ReadTest < ActiveSupport::TestCase
  setup do
    @json = file_fixture("scripture_1_sam_16.json").read
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "extracts title summary and verses and drops study notes" do
    chapter = read_fixture(cite: "1 Samuel 16:13")

    assert_equal "1 Samuel 16", chapter.title
    assert_equal "Jehová escoge a David, de Belén, como rey.", chapter.summary
    assert_equal [ 1, 2, 13 ], chapter.verses.map(&:number)
    assert_equal "Y dijo Jehová a Samuel: ve a Isaí de Belén.", chapter.verses.first.text
    assert_equal [ 13 ], chapter.focus
    assert_includes chapter.source_url, "/study/scriptures/ot/1-sam/16?lang=spa"
    refute_includes chapter.verses.map(&:text).join, "GEE NOTE SHOULD NOT APPEAR"
    refute_includes chapter.verses.first.text, "aIsaí"
  end

  test "highlights a verse range from the cite" do
    chapter = read_fixture(cite: "1 Samuel 16:1–2")

    assert_equal [ 1, 2 ], chapter.focus
  end

  test "skips unknown studies without hitting the network" do
    called = false
    Scriptures::Read.fetcher = ->(*) { called = true; @json }
    assert_nil Scriptures::Read.call(study: "ot/gen/1", locale: :es, cache: @cache)
    refute called
  end

  test "returns nil when the church payload is missing verses" do
    Scriptures::Read.fetcher = ->(*) { { "meta" => { "title" => "Empty" }, "content" => { "body" => "<p>nope</p>" } }.to_json }
    assert_nil Scriptures::Read.call(study: "ot/1-sam/16", locale: :es, cache: @cache)
  end

  test "returns nil on timeout" do
    Scriptures::Read.fetcher = ->(*) { raise Net::OpenTimeout }
    assert_nil Scriptures::Read.call(study: "ot/1-sam/16", locale: :es, cache: @cache)
  end

  test "asks the church api in the active language" do
    uri = nil
    Scriptures::Read.fetcher = ->(value) { uri = value; @json }
    I18n.with_locale(:fr) { Scriptures::Read.call(study: "ot/1-sam/16", cache: @cache) }

    assert_includes uri.to_s, "lang=fra"
    assert_includes uri.to_s, "uri=%2Fscriptures%2Fot%2F1-sam%2F16"
  end

  test "caches a successful chapter so a second read stays local" do
    hits = 0
    Scriptures::Read.fetcher = ->(*) { hits += 1; @json }
    2.times { Scriptures::Read.call(study: "ot/1-sam/16", locale: :es, cache: @cache) }
    assert_equal 1, hits
  end

  test "caches a miss briefly so a timeout is not hammered" do
    hits = 0
    Scriptures::Read.fetcher = ->(*) { hits += 1; raise Net::OpenTimeout }
    2.times { assert_nil Scriptures::Read.call(study: "ot/1-sam/16", locale: :es, cache: @cache) }
    assert_equal 1, hits
  end

  test "focus_verses parses a single verse and a hyphen range" do
    assert_equal [ 13 ], Scriptures::Read.focus_verses("1 Samuel 16:13")
    assert_equal [ 2, 3 ], Scriptures::Read.focus_verses("1 Reyes 21:2-3")
    assert_equal [], Scriptures::Read.focus_verses("")
  end

  private

    def read_fixture(cite:)
      Scriptures::Read.fetcher = ->(*) { @json }
      I18n.with_locale(:es) { Scriptures::Read.call(study: "ot/1-sam/16", cite:, cache: @cache) }
    end
end
