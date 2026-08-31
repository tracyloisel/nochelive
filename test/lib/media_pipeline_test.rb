require "test_helper"
require Rails.root.join("lib/media_pipeline")
require "tmpdir"

class MediaPipelineTest < ActiveSupport::TestCase
  test "the Library daily hero role owns three exclusive art-directed renditions" do
    config = YAML.safe_load_file(Rails.root.join("config/media/responsive.yml"))
    role = config.dig("roles", "library_daily_hero")

    assert_equal "portrait", role.fetch("default_rendition")
    assert_equal %w[portrait tablet landscape], role.fetch("renditions").keys
    assert_equal %w[9:16 4:5 16:9], role.fetch("renditions").values.pluck("ratio")
    media_queries = role.fetch("renditions").values.pluck("media")
    assert media_queries.all?(&:present?)
    assert_equal media_queries.size, media_queries.uniq.size
    assert_equal 0.005, role.fetch("source_ratio_tolerance")
    daily_assets = config.fetch("assets").select { |_key, asset| asset["role"] == "library_daily_hero" }
    assert_equal 7, daily_assets.size
    daily_assets.each do |key, asset|
      reference = key.match(/\.ps(?<reference>\d+(?:-\d+)?)\./)[:reference]
      sources = [ asset.fetch("source"), *asset.fetch("sources").values ]

      assert_equal %w[landscape tablet], asset.fetch("sources").keys.sort
      assert sources.all? { |source| File.basename(source).start_with?("ps#{reference}-") },
        "daily Library filenames must begin with their Bible reference: #{key}"
    end
  end

  test "catalog build is deterministic and keeps the master outside public" do
    Dir.mktmpdir("noche-media-pipeline") do |directory|
      root = Pathname(directory)
      master = root.join("media/masters/media/sample/portrait.png")
      master.dirname.mkpath
      _stdout, stderr, status = Open3.capture3(
        "magick", "-size", "800x1200", "xc:#2b4166", master.to_s
      )
      assert status.success?, stderr

      config = root.join("responsive.yml")
      config.write(<<~YAML)
        version: 1
        source_root: media/masters
        catalog:
          include: media/**/*
          icon_max: 128
          landscape_ratio: 1.2
          portrait_ratio: 1.2
        roles:
          catalog_portrait:
            widths: [390, 768]
            sizes: 100vw
            quality:
              avif: 48
              webp: 74
              jpeg: 78
          catalog_landscape:
            widths: [390]
            sizes: 100vw
            quality: { avif: 48, webp: 74, jpeg: 78 }
          catalog_square:
            widths: [390]
            sizes: 100vw
            quality: { avif: 48, webp: 74, jpeg: 78 }
          catalog_icon:
            widths: [64]
            sizes: 64px
            quality: { avif: 48, webp: 74, jpeg: 78 }
        assets: {}
      YAML
      manifest_path = root.join("manifest.json")
      previous_jobs = ENV["MEDIA_JOBS"]
      ENV["MEDIA_JOBS"] = "2"

      first = MediaPipeline.new(root:, config_path: config, manifest_path:).call
      second = MediaPipeline.new(root:, config_path: config, manifest_path:).call

      assert_equal first, second
      asset = first.fetch("assets").fetch("catalog.sample.portrait")
      assert_equal "catalog_portrait", asset.fetch("role")
      assert_equal 3, asset.dig("variants", "avif").size
      assert_equal %w[avif jpeg webp], asset.fetch("variants").keys.sort
      assert master.file?
      refute root.join("public/media/sample/portrait.png").exist?
      asset.fetch("variants").values.flatten.each do |variant|
        output = root.join("public", variant.fetch("src").delete_prefix("/"))
        assert output.file?
        assert_equal variant.fetch("sha256"), Digest::SHA256.file(output).hexdigest
      end
    ensure
      ENV["MEDIA_JOBS"] = previous_jobs
    end
  end

  test "an art-directed asset keeps per-rendition sources and focuses without upscaling" do
    Dir.mktmpdir("noche-media-renditions") do |directory|
      root = Pathname(directory)
      portrait = root.join("media/masters/media/sample/hero.png")
      tablet = root.join("media/masters/media/sample/hero-tablet.png")
      landscape = root.join("media/masters/media/sample/hero-landscape.png")
      portrait.dirname.mkpath
      [ [ portrait, "900x1600" ], [ tablet, "800x1000" ], [ landscape, "1600x900" ] ].each do |path, size|
        _stdout, stderr, status = Open3.capture3("magick", "-size", size, "xc:#2b4166", path.to_s)
        assert status.success?, stderr
      end

      config = root.join("responsive.yml")
      config.write(<<~YAML)
        version: 1
        source_root: media/masters
        roles:
          library_daily_hero:
            default_rendition: portrait
            source_ratio_tolerance: 0.005
            renditions:
              portrait:
                widths: [390, 900, 1200]
                sizes: 100vw
                ratio: "9:16"
                media: "(max-width: 599px) and (orientation: portrait)"
              tablet:
                widths: [600, 800, 1200]
                sizes: 100vw
                ratio: "4:5"
                media: "(min-width: 600px) and (orientation: portrait)"
              landscape:
                widths: [768, 1600, 1920]
                sizes: 100vw
                ratio: "16:9"
                media: "(orientation: landscape)"
            quality: { avif: 48, webp: 74, jpeg: 78 }
        assets:
          scripture.library.daily.sample:
            source: media/sample/hero.png
            sources:
              tablet: media/sample/hero-tablet.png
              landscape: media/sample/hero-landscape.png
            focuses:
              portrait: "68% 34%"
              tablet: "72% 43%"
              landscape: "76% 46%"
            focus: "72% 43%"
            role: library_daily_hero
      YAML

      manifest = MediaPipeline.new(
        root:,
        config_path: config,
        manifest_path: root.join("manifest.json")
      ).call

      assert_equal [ "scripture.library.daily.sample" ], manifest.fetch("assets").keys
      asset = manifest.dig("assets", "scripture.library.daily.sample")
      assert_equal "media/sample/hero.png", asset.dig("renditions", "portrait", "source")
      assert_equal 900, asset.dig("renditions", "portrait", "source_width")
      assert_equal "68% 34%", asset.dig("renditions", "portrait", "focus")
      assert_equal "media/sample/hero-tablet.png", asset.dig("renditions", "tablet", "source")
      assert_equal "72% 43%", asset.dig("renditions", "tablet", "focus")
      assert_equal "media/sample/hero-landscape.png", asset.dig("renditions", "landscape", "source")
      assert_equal 1600, asset.dig("renditions", "landscape", "source_width")
      assert_equal "76% 46%", asset.dig("renditions", "landscape", "focus")
      assert_equal({ "portrait" => "68% 34%", "tablet" => "72% 43%", "landscape" => "76% 46%" }, asset.fetch("focuses"))
      assert_equal [ 390, 900 ], asset.dig("renditions", "portrait", "variants", "avif").pluck("width")
      assert_equal [ 600, 800 ], asset.dig("renditions", "tablet", "variants", "avif").pluck("width")
      assert_equal [ 768, 1600 ], asset.dig("renditions", "landscape", "variants", "avif").pluck("width")
    end
  end

  test "a strict art-directed role rejects a master with the wrong ratio" do
    Dir.mktmpdir("noche-media-ratio") do |directory|
      root = Pathname(directory)
      master = root.join("media/masters/media/sample/hero.png")
      master.dirname.mkpath
      _stdout, stderr, status = Open3.capture3("magick", "-size", "800x1200", "xc:#2b4166", master.to_s)
      assert status.success?, stderr

      config = root.join("responsive.yml")
      config.write(<<~YAML)
        version: 1
        source_root: media/masters
        roles:
          library_daily_hero:
            source_ratio_tolerance: 0.005
            widths: [390]
            sizes: 100vw
            ratio: "9:16"
            quality: { avif: 48, webp: 74, jpeg: 78 }
        assets:
          scripture.library.daily.sample:
            source: media/sample/hero.png
            role: library_daily_hero
      YAML

      error = assert_raises(RuntimeError) do
        MediaPipeline.new(root:, config_path: config, manifest_path: root.join("manifest.json")).call
      end
      assert_match(/source ratio mismatch/, error.message)
      assert_match(/media\/sample\/hero\.png/, error.message)
    end
  end

  test "a ratio crop never enlarges either source dimension" do
    Dir.mktmpdir("noche-media-no-upscale") do |directory|
      root = Pathname(directory)
      master = root.join("media/masters/media/sample/wide.png")
      master.dirname.mkpath
      _stdout, stderr, status = Open3.capture3("magick", "-size", "800x400", "xc:#2b4166", master.to_s)
      assert status.success?, stderr

      config = root.join("responsive.yml")
      config.write(<<~YAML)
        version: 1
        source_root: media/masters
        roles:
          cropped:
            widths: [390, 768]
            sizes: 100vw
            ratio: "9:16"
            quality: { avif: 48, webp: 74, jpeg: 78 }
        assets:
          sample.crop:
            source: media/sample/wide.png
            role: cropped
      YAML

      manifest = MediaPipeline.new(root:, config_path: config, manifest_path: root.join("manifest.json")).call
      variants = manifest.dig("assets", "sample.crop", "variants", "avif")
      assert_equal [ 225 ], variants.pluck("width")
      assert_equal [ 400 ], variants.pluck("height")
    end
  end

  test "an unused role does not require any media source" do
    Dir.mktmpdir("noche-media-unused-role") do |directory|
      root = Pathname(directory)
      config = root.join("responsive.yml")
      config.write(<<~YAML)
        version: 1
        source_root: media/masters
        roles:
          library_daily_hero:
            widths: [390]
            sizes: 100vw
            ratio: "9:16"
            quality: { avif: 48, webp: 74, jpeg: 78 }
        assets: {}
      YAML

      manifest = MediaPipeline.new(root:, config_path: config, manifest_path: root.join("manifest.json")).call
      assert_empty manifest.fetch("assets")

      config.write(config.read.sub("assets: {}", <<~YAML.chomp))
        assets:
          scripture.library.daily.missing:
            source: media/library/missing.png
            role: library_daily_hero
      YAML
      error = assert_raises(RuntimeError) do
        MediaPipeline.new(root:, config_path: config, manifest_path: root.join("manifest.json")).call
      end
      assert_match(/missing media source: media\/library\/missing\.png/, error.message)
    end
  end
end
