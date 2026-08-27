#!/usr/bin/env ruby
# frozen_string_literal: true

# Hub "Notre communauté" stat icons (gold + ink pairs).
# Rasterize script/community_icons/*.svg → public/media/ui/community-*.png
# (OpenRouter Flux filled the frame; keep these glyphs for a sharp 28px HUD.)
#
#   ruby script/generate_community_icons.rb
#   ruby script/generate_community_icons.rb --force
#   ruby script/generate_community_icons.rb --only people-gold,temple-ink

require "fileutils"
require "open3"
require "optparse"

ROOT = File.expand_path("..", __dir__)
SVG_DIR = File.join(ROOT, "script/community_icons")
OUT_DIR = File.join(ROOT, "public/media/ui")
SLUGS = %w[people-gold people-ink chat-gold chat-ink temple-gold temple-ink].freeze

force = false
only = nil
OptionParser.new do |opts|
  opts.on("--force") { force = true }
  opts.on("--only LIST") { |value| only = value.split(",").map(&:strip) }
end.parse!

FileUtils.mkdir_p(OUT_DIR)
SLUGS.each do |slug|
  next if only && !only.include?(slug)

  src = File.join(SVG_DIR, "#{slug}.svg")
  dest = File.join(OUT_DIR, "community-#{slug}.png")
  abort "missing #{src}" unless File.exist?(src)
  if File.exist?(dest) && !force
    puts "skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end

  cmd = [ "magick", "-background", "none", src, "-resize", "128x128", dest ]
  _out, err, status = Open3.capture3(*cmd)
  abort "magick failed for #{slug}: #{err}" unless status.success?
  puts "wrote #{dest.delete_prefix("#{ROOT}/")}"
end
