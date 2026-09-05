#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "shellwords"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
LIBRARY_ROOT = File.join(ROOT, "media/masters/media/study/library/daily/psalms-102-150-fast")
CAMPAIGN_ROOT = File.join(ROOT, "media/masters/media/expeditions/psalms-102-150-fast")

LIBRARY_DAYS = [
  [ "ps136-mercy-refrain", "media/masters/media/quizzes/psalms_living_god/fast-psalms-pack01-q03.png" ],
  [ "ps110-118-servant-king", "media/masters/media/quizzes/psalms_servant_king/fast-psalms-pack02-q10.png" ],
  [ "ps139-known", "media/masters/media/quizzes/psalms_hears_knows/fast-psalms-pack03-q10.png" ],
  [ "ps119-lamp", "media/masters/media/quizzes/psalms_walk_with_god/fast-psalms-pack04-q04.png" ],
  [ "ps147-build-heal", "media/masters/media/quizzes/psalms_build_home/fast-psalms-pack05-q10.png" ],
  [ "ps150-return", "media/masters/media/quizzes/psalms_every_breath/fast-psalms-pack06-q08.png" ]
].freeze

CAMPAIGN_SOURCES = {
  "portrait" => "media/masters/media/expeditions/psalms-102-150-fast/ps110-118-roi-serviteur-portrait-v1.png",
  "tablet" => "media/masters/media/expeditions/psalms-102-150-fast/ps110-118-roi-serviteur-tablet-v1.png",
  "landscape" => "media/masters/media/expeditions/psalms-102-150-fast/ps110-118-roi-serviteur-landscape-v1.png"
}.freeze

def run!(*command)
  return if system(*command)

  raise "Command failed: #{command.join(' ')}"
end

def compose_art_directed(source, stem)
  portrait = File.join(LIBRARY_ROOT, "#{stem}-portrait-v1.png")
  tablet = File.join(LIBRARY_ROOT, "#{stem}-tablet-v1.png")
  landscape = File.join(LIBRARY_ROOT, "#{stem}-landscape-v1.png")

  run!("magick", source, "-auto-orient", "-resize", "1080x1920^", "-gravity", "center", "-extent", "1080x1920", portrait)

  Dir.mktmpdir("psalms-fast-media") do |temporary|
    tablet_background = File.join(temporary, "tablet-background.png")
    tablet_foreground = File.join(temporary, "tablet-foreground.png")
    tablet_mask = File.join(temporary, "tablet-mask.png")
    tablet_faded = File.join(temporary, "tablet-faded.png")
    tablet_scrim = File.join(temporary, "tablet-scrim.png")

    run!("magick", source, "-auto-orient", "-resize", "1440x1800^", "-gravity", "center", "-extent", "1440x1800", "-blur", "0x34", "-brightness-contrast", "-26x-8", tablet_background)
    run!("magick", source, "-auto-orient", "-resize", "x1800", tablet_foreground)
    run!("magick", "-size", "1013x1800", "xc:white", "-alpha", "set", "-channel", "A", "-fx", "i<180 ? i/180 : 1", tablet_mask)
    run!("magick", tablet_foreground, tablet_mask, "-alpha", "off", "-compose", "CopyOpacity", "-composite", tablet_faded)
    run!("magick", "-size", "1440x1800", "xc:#07111d", "-alpha", "set", "-channel", "A", "-fx", "0.82*(1-i/(w-1))^2", tablet_scrim)
    run!("magick", tablet_background, tablet_faded, "-gravity", "east", "-compose", "over", "-composite", tablet_scrim, "-compose", "over", "-composite", tablet)

    landscape_background = File.join(temporary, "landscape-background.png")
    landscape_foreground = File.join(temporary, "landscape-foreground.png")
    landscape_mask = File.join(temporary, "landscape-mask.png")
    landscape_faded = File.join(temporary, "landscape-faded.png")
    landscape_scrim = File.join(temporary, "landscape-scrim.png")

    run!("magick", source, "-auto-orient", "-resize", "1920x1080^", "-gravity", "center", "-extent", "1920x1080", "-blur", "0x32", "-brightness-contrast", "-28x-8", landscape_background)
    run!("magick", source, "-auto-orient", "-resize", "720x", "-gravity", "north", "-crop", "720x1080+0+0", "+repage", landscape_foreground)
    run!("magick", "-size", "720x1080", "xc:white", "-alpha", "set", "-channel", "A", "-fx", "i<180 ? i/180 : 1", landscape_mask)
    run!("magick", landscape_foreground, landscape_mask, "-alpha", "off", "-compose", "CopyOpacity", "-composite", landscape_faded)
    run!("magick", "-size", "1920x1080", "xc:#07111d", "-alpha", "set", "-channel", "A", "-fx", "0.84*(1-i/(w-1))^2", landscape_scrim)
    run!("magick", landscape_background, landscape_faded, "-gravity", "east", "-compose", "over", "-composite", landscape_scrim, "-compose", "over", "-composite", landscape)
  end

  { "portrait" => portrait, "tablet" => tablet, "landscape" => landscape }
end

FileUtils.mkdir_p(LIBRARY_ROOT)
FileUtils.mkdir_p(CAMPAIGN_ROOT)

outputs = LIBRARY_DAYS.flat_map do |stem, relative_source|
  source = File.join(ROOT, relative_source)
  raise "Missing approved Library source #{source}" unless File.file?(source)

  compose_art_directed(source, stem).values
end

CAMPAIGN_SOURCES.each do |rendition, relative_source|
  source = File.join(ROOT, relative_source)
  raise "Missing approved campaign source #{source}" unless File.file?(source)

  target = File.join(CAMPAIGN_ROOT, "ps110-118-roi-serviteur-#{rendition}-v1.png")
  FileUtils.cp(source, target) unless File.expand_path(source) == File.expand_path(target)
  outputs << target
end


expected_dimensions = {
  "portrait" => "1080x1920",
  "tablet" => "1440x1800",
  "landscape" => "1920x1080"
}.freeze
outputs.each do |path|
  rendition = expected_dimensions.keys.find { |name| File.basename(path).include?("-#{name}-") }
  dimensions = `magick identify -format %wx%h #{Shellwords.escape(path)}`
  raise "Unexpected dimensions for #{path}: #{dimensions}" unless dimensions == expected_dimensions.fetch(rendition)
end

puts "Built #{outputs.size} approved mechanical masters with zero generation calls."
