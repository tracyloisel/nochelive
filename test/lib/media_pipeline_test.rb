require "test_helper"
require Rails.root.join("lib/media_pipeline")
require "tmpdir"

class MediaPipelineTest < ActiveSupport::TestCase
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

  test "a rendition can use its own art-directed master" do
    Dir.mktmpdir("noche-media-renditions") do |directory|
      root = Pathname(directory)
      portrait = root.join("media/masters/media/sample/hero.png")
      landscape = root.join("media/masters/media/sample/hero-landscape.png")
      portrait.dirname.mkpath
      [ [ portrait, "800x1200" ], [ landscape, "1600x900" ] ].each do |path, size|
        _stdout, stderr, status = Open3.capture3("magick", "-size", size, "xc:#2b4166", path.to_s)
        assert status.success?, stderr
      end

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
          hub_backdrop:
            default_rendition: portrait
            renditions:
              portrait:
                widths: [390]
                sizes: 100vw
                ratio: "9:16"
                media: "(max-width: 767px)"
              landscape:
                widths: [768, 1440]
                sizes: 100vw
                ratio: "16:9"
                media: "(min-width: 768px)"
            quality: { avif: 48, webp: 74, jpeg: 78 }
          catalog_portrait:
            widths: [390]
            sizes: 100vw
            quality: { avif: 48, webp: 74, jpeg: 78 }
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
        assets:
          hub.hero:
            source: media/sample/hero.png
            sources:
              landscape: media/sample/hero-landscape.png
            role: hub_backdrop
      YAML

      manifest = MediaPipeline.new(
        root:,
        config_path: config,
        manifest_path: root.join("manifest.json")
      ).call

      assert_equal [ "hub.hero" ], manifest.fetch("assets").keys
      asset = manifest.dig("assets", "hub.hero")
      assert_equal "media/sample/hero.png", asset.dig("renditions", "portrait", "source")
      assert_equal 800, asset.dig("renditions", "portrait", "source_width")
      assert_equal "media/sample/hero-landscape.png", asset.dig("renditions", "landscape", "source")
      assert_equal 1600, asset.dig("renditions", "landscape", "source_width")
      assert_equal [ 768, 1440 ], asset.dig("renditions", "landscape", "variants", "avif").pluck("width")
    end
  end
end
