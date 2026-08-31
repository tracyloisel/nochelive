require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "Noche title and artwork come from the first quiz pack" do
    night = game_sessions(:david)

    assert_equal night.primary_quiz_pack.copy(:title), night_title(night)
    assert_equal street_still_src(night.primary_quiz_pack.question_at(1)), night_still_src(night)
  end

  test "every Noche links to its canonical URL including finished nights" do
    assert_equal night_path(game_sessions(:david).code), home_night_path_for(game_sessions(:david))
    assert_equal night_path(game_sessions(:cerrada).code), home_night_path_for(game_sessions(:cerrada))
  end

  test "Noche picture emits JPEG sources and exposes every art-directed focus" do
    with_media_asset(daily_hero_asset) do
      fragment = Nokogiri::HTML.fragment(
        noche_picture(
          "scripture.library.daily.sample",
          role: :library_daily_hero,
          alt: "Illustration dramatisée",
          class_name: "daily-hero",
          loading: "eager",
          fetchpriority: "high"
        )
      )

      assert_equal 9, fragment.css("picture source").size
      assert_equal 3, fragment.css('picture source[type="image/jpeg"]').size
      assert_equal daily_hero_media_queries, fragment.css('picture source[type="image/jpeg"]').map { |source| source["media"] }

      image = fragment.at_css("picture img")
      assert_equal "68% 34%", image["data-media-focus-portrait"]
      assert_equal "72% 43%", image["data-media-focus-tablet"]
      assert_equal "76% 46%", image["data-media-focus-landscape"]
      assert_equal "eager", image["loading"]
      assert_equal "high", image["fetchpriority"]
    end
  end

  test "Noche picture preload keeps daily hero renditions mutually exclusive" do
    with_media_asset(daily_hero_asset) do
      fragment = Nokogiri::HTML.fragment(
        noche_picture_preload("scripture.library.daily.sample", role: :library_daily_hero)
      )

      links = fragment.css('link[rel="preload"]')
      assert_equal 3, links.size
      assert_equal daily_hero_media_queries, links.map { |link| link["media"] }
      assert_equal 3, links.map { |link| link["media"] }.uniq.size
      assert links.all? { |link| link["imagesrcset"].present? }
      assert links.all? { |link| link["imagesizes"] == "100vw" }
    end
  end

  private

    def with_media_asset(asset)
      original_fetch = Frontend::MediaManifest.method(:fetch)
      Frontend::MediaManifest.singleton_class.send(:define_method, :fetch) { |_key| asset }
      yield
    ensure
      Frontend::MediaManifest.singleton_class.send(:define_method, :fetch) { |key| original_fetch.call(key) }
    end

    def daily_hero_media_queries
      [
        "(max-width: 599px) and (orientation: portrait)",
        "(min-width: 600px) and (orientation: portrait)",
        "(orientation: landscape)"
      ]
    end

    def daily_hero_asset
      rendition = lambda do |name, media, focus, width, height|
        variants = %w[avif webp jpeg].to_h do |format|
          extension = format == "jpeg" ? "jpg" : format
          [ format, [ { "src" => "/media/#{name}-#{width}.#{extension}", "width" => width, "height" => height } ] ]
        end
        {
          "media" => media,
          "sizes" => "100vw",
          "focus" => focus,
          "variants" => variants
        }
      end

      renditions = {
        "portrait" => rendition.call("portrait", daily_hero_media_queries[0], "68% 34%", 390, 693),
        "tablet" => rendition.call("tablet", daily_hero_media_queries[1], "72% 43%", 768, 960),
        "landscape" => rendition.call("landscape", daily_hero_media_queries[2], "76% 46%", 1440, 810)
      }
      {
        "role" => "library_daily_hero",
        "focus" => "72% 43%",
        "sizes" => "100vw",
        "variants" => renditions.fetch("portrait").fetch("variants"),
        "renditions" => renditions
      }
    end
end
