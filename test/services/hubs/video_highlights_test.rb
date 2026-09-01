require "test_helper"

class Hubs::VideoHighlightsTest < ActiveSupport::TestCase
  test "returns at most six catalog-validated videos in catalog order" do
    videos = 8.times.map { |index| video(format("video%06d", index)) }
    locales = []
    catalog = lambda do |locale:|
      locales << locale
      result(videos:)
    end

    highlights = Hubs::VideoHighlights.call(locale: :fr, catalog:)

    assert_equal videos.first(6), highlights
    assert_equal [ "fr" ], locales
  end

  test "returns no highlights for unavailable catalogs or an empty page" do
    [ :not_configured, :unavailable, nil ].each do |error|
      videos = error.nil? ? [] : [ video("abc123DEF_4") ]
      catalog = ->(locale:) { result(videos:, error:) }

      assert_empty Hubs::VideoHighlights.call(locale: :es, catalog:)
    end
  end

  test "fails closed when the catalog raises" do
    catalog = ->(locale:) { raise Net::ReadTimeout }

    assert_empty Hubs::VideoHighlights.call(locale: :en, catalog:)
  end

  private

    def result(videos:, error: nil)
      ChurchVideos::Catalog::Result.new(videos:, error:)
    end

    def video(id)
      ChurchVideos::Catalog::Video.new(
        id:,
        title: "Video #{id}",
        description: "",
        published_at: Time.utc(2026, 8, 20, 12, 30),
        duration_seconds: 183,
        made_for_kids: false
      )
    end
end
