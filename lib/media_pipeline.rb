require "digest"
require "fileutils"
require "json"
require "open3"
require "set"
require "thread"
require "yaml"

class MediaPipeline
  RASTER_EXTENSIONS = %w[.jpg .jpeg .png .webp].freeze
  SOURCE_PRIORITY = { ".png" => 0, ".jpg" => 1, ".jpeg" => 2, ".webp" => 3 }.freeze
  FORMATS = {
    "avif" => { extension: "avif", mime: "image/avif" },
    "webp" => { extension: "webp", mime: "image/webp" },
    "jpeg" => { extension: "jpg", mime: "image/jpeg" }
  }.freeze

  def initialize(root: Rails.root, config_path: nil, manifest_path: nil)
    @root = Pathname(root)
    @config_path = Pathname(config_path || @root.join("config/media/responsive.yml"))
    @manifest_path = Pathname(manifest_path || @root.join("config/media/generated_manifest.json"))
  end

  def call
    config = YAML.safe_load_file(@config_path)
    @source_root = @root.join(config.fetch("source_root", "public"))
    roles = config.fetch("roles")
    assets = catalog_assets(config, roles).merge(config.fetch("assets", {}))
    manifest = {
      "version" => config.fetch("version"),
      "source_root" => @source_root.relative_path_from(@root).to_s,
      "assets" => {}
    }

    manifest["assets"] = build_assets(assets.sort, roles).to_h

    build_compatibility_assets(config, manifest)
    prune_stale_variants(manifest)
    FileUtils.mkdir_p(@manifest_path.dirname)
    @manifest_path.write(JSON.pretty_generate(manifest) + "\n")
    manifest
  end

  private

    def catalog_assets(config, roles)
      catalog = config["catalog"]
      return {} unless catalog

      patterns = Array(catalog.fetch("include", "media/**/*"))
      files = patterns.flat_map { |pattern| @source_root.glob(pattern) }
        .select { |path| path.file? && RASTER_EXTENSIONS.include?(path.extname.downcase) }
      groups = files.group_by { |path| source_stem(path.relative_path_from(@source_root).to_s) }
      explicit_stems = config.fetch("assets", {}).values.flat_map do |row|
        [ row.fetch("source"), *row.fetch("sources", {}).values ]
      end.map { |source| source_stem(source) }.to_set

      groups.sort.to_h.filter_map do |stem, candidates|
        next if explicit_stems.include?(stem)

        source = candidates.min_by { |path| SOURCE_PRIORITY.fetch(path.extname.downcase) }
        width, height = identify(source)
        role = catalog_role(width, height, catalog, roles)
        logical = source.relative_path_from(@source_root).to_s
        key = "catalog.#{stem.delete_prefix('media/').tr('/', '.')}"
        [ key, {
          "source" => logical,
          "role" => role,
          "focus" => "50% 50%",
          "theme" => "neutral"
        } ]
      end.to_h
    end

    def catalog_role(width, height, catalog, roles)
      requested = if [ width, height ].max <= catalog.fetch("icon_max", 512).to_i
        "catalog_icon"
      elsif width.to_f / height >= catalog.fetch("landscape_ratio", 1.2).to_f
        "catalog_landscape"
      elsif height.to_f / width >= catalog.fetch("portrait_ratio", 1.2).to_f
        "catalog_portrait"
      else
        "catalog_square"
      end
      raise "missing media role: #{requested}" unless roles.key?(requested)

      requested
    end

    def build_assets(rows, roles)
      jobs = ENV.fetch("MEDIA_JOBS", "1").to_i.clamp(1, 12)
      return rows.map { |key, row| [ key, build_asset(key, row, roles.fetch(row.fetch("role"))) ] } if jobs == 1

      queue = Queue.new
      rows.each_with_index { |row, index| queue << [ index, row ] }
      results = Array.new(rows.size)
      errors = Queue.new
      workers = jobs.times.map do
        Thread.new do
          loop do
            index, pair = queue.pop(true)
            key, row = pair
            results[index] = [ key, build_asset(key, row, roles.fetch(row.fetch("role"))) ]
          rescue ThreadError
            break
          rescue StandardError => error
            errors << error
            break
          end
        end
      end
      workers.each(&:join)
      raise errors.pop unless errors.empty?

      results
    end

    def build_asset(key, row, role)
      source_rel = row.fetch("source")
      source = @source_root.join(source_rel)
      raise "missing media source: #{source_rel}" unless source.file?

      source_width, source_height = identify(source)
      source_digest = Digest::SHA256.file(source).hexdigest
      renditions = build_renditions(key, row, source, source_digest, source_width, source_height, role)
      primary = renditions.fetch(role.fetch("default_rendition", renditions.keys.first))

      {
        "role" => row.fetch("role"),
        "source" => source_rel,
        "source_sha256" => source_digest,
        "source_width" => source_width,
        "source_height" => source_height,
        "source_bytes" => source.size,
        "ratio" => format("%.4f", source_width.to_f / source_height),
        "focus" => row.fetch("focus", "50% 50%"),
        "theme" => row.fetch("theme", "neutral"),
        "sizes" => primary.fetch("sizes"),
        "variants" => primary.fetch("variants"),
        "renditions" => renditions
      }
    end

    def build_renditions(key, row, source, digest, source_width, source_height, role)
      definitions = role["renditions"] || {
        "default" => {
          "widths" => role.fetch("widths"),
          "sizes" => role.fetch("sizes"),
          "ratio" => nil,
          "media" => nil
        }
      }
      source_overrides = row.fetch("sources", {})

      definitions.to_h do |name, rendition|
        rendition_source_rel = source_overrides.fetch(name, row.fetch("source"))
        rendition_source = @source_root.join(rendition_source_rel)
        raise "missing media source: #{rendition_source_rel}" unless rendition_source.file?

        if rendition_source == source
          rendition_digest = digest
          rendition_width = source_width
          rendition_height = source_height
        else
          rendition_digest = Digest::SHA256.file(rendition_source).hexdigest
          rendition_width, rendition_height = identify(rendition_source)
        end
        widths = Array(rendition.fetch("widths")).map(&:to_i)
          .select { |width| width.positive? && width <= rendition_width }.uniq.sort
        widths << rendition_width if rendition["ratio"].blank? && !widths.include?(rendition_width)
        widths = [ rendition_width ] if widths.empty?
        variants = build_variants(
          key, rendition_source, rendition_digest, widths, role,
          rendition: name,
          ratio: rendition["ratio"],
          focus: rendition.fetch("focus", "50% 50%")
        )
        [ name, {
          "source" => rendition_source_rel,
          "source_sha256" => rendition_digest,
          "source_width" => rendition_width,
          "source_height" => rendition_height,
          "source_bytes" => rendition_source.size,
          "media" => rendition["media"],
          "ratio" => rendition["ratio"] || format("%.4f", rendition_width.to_f / rendition_height),
          "sizes" => rendition.fetch("sizes"),
          "variants" => variants
        } ]
      end
    end

    def build_variants(key, source, digest, widths, role, rendition:, ratio:, focus:)
      FORMATS.to_h do |format, format_data|
        quality = role.fetch("quality").fetch(format).to_i
        rows = widths.map do |width|
          output = output_path(key, digest, width, format_data.fetch(:extension), rendition:)
          generate(source, output, width, quality, format, ratio:, focus:)
          out_width, out_height = identify(output)
          {
            "src" => "/#{output.relative_path_from(@root.join('public'))}",
            "width" => out_width,
            "height" => out_height,
            "bytes" => output.size,
            "sha256" => Digest::SHA256.file(output).hexdigest
          }
        end
        [ format, rows ]
      end
    end

    def output_path(key, digest, width, extension, rendition:)
      slug = key.tr(".", "/")
      suffix = rendition == "default" ? "" : "-#{rendition}"
      path = @root.join("public/media/generated", slug, "#{digest.first(12)}#{suffix}-#{width}.#{extension}")
      FileUtils.mkdir_p(path.dirname)
      path
    end

    def generate(source, output, width, quality, format, ratio: nil, focus: "50% 50%")
      return if output.file?

      command = [ "magick", source.to_s, "-auto-orient", "-strip" ]
      if ratio.present?
        ratio_width, ratio_height = ratio.split(":").map(&:to_f)
        height = (width * ratio_height / ratio_width).round
        command.concat([ "-resize", "#{width}x#{height}^", "-gravity", gravity_for(focus), "-extent", "#{width}x#{height}" ])
      else
        command.concat([ "-resize", "#{width}x>" ])
      end
      command.concat([ "-background", "white", "-alpha", "remove" ]) if format == "jpeg"
      command.concat([ "-interlace", "Plane" ]) if format == "jpeg"
      command.concat([ "-quality", quality.to_s, output.to_s ])
      _stdout, stderr, status = Open3.capture3(*command)
      raise "media build failed for #{source}: #{stderr}" unless status.success?
    end

    def gravity_for(focus)
      x, y = focus.to_s.scan(/[\d.]+/).map(&:to_f)
      horizontal = x && x < 34 ? "West" : (x && x > 66 ? "East" : "")
      vertical = y && y < 34 ? "North" : (y && y > 66 ? "South" : "")
      "#{vertical}#{horizontal}".presence || "Center"
    end

    def build_compatibility_assets(config, manifest)
      Array(config["compatibility"]).each do |logical|
        asset = manifest.fetch("assets").values.find { |row| source_stem(row.fetch("source")) == source_stem(logical) }
        raise "missing compatibility media source: #{logical}" unless asset

        format = File.extname(logical).downcase.delete_prefix(".")
        format = "jpeg" if %w[jpg jpeg].include?(format)
        variant = asset.fetch("variants").fetch(format).last
        source = @root.join("public", variant.fetch("src").delete_prefix("/"))
        destination = @root.join("public", logical.delete_prefix("/"))
        FileUtils.mkdir_p(destination.dirname)
        FileUtils.cp(source, destination)
      end
    end

    def source_stem(path)
      path.to_s.delete_prefix("/").sub(/\.(?:jpe?g|png|webp)\z/i, "")
    end

    def identify(path)
      stdout, stderr, status = Open3.capture3("identify", "-format", "%w %h", path.to_s)
      raise "identify failed for #{path}: #{stderr}" unless status.success?

      stdout.split.map(&:to_i)
    end

    def prune_stale_variants(manifest)
      output_root = @root.join("public/media/generated")
      return unless output_root.directory?

      expected = manifest.fetch("assets").values.flat_map do |asset|
        asset.fetch("renditions").values.flat_map { |rendition| rendition.fetch("variants").values.flatten }.map do |variant|
          @root.join("public", variant.fetch("src").delete_prefix("/"))
        end
      end.to_set
      output_root.glob("**/*").select(&:file?).each do |path|
        FileUtils.rm_f(path) unless expected.include?(path)
      end
      output_root.glob("**/*").select(&:directory?).sort_by { |path| -path.to_s.length }.each do |path|
        Dir.rmdir(path) if path.children.empty?
      end
    end
end
