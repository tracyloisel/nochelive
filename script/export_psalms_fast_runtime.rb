#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
MANIFEST_PATH = File.join(ROOT, "config/expeditions/psalms-102-150-fast.yml")
STILLS_PATH = File.join(ROOT, "config/media/quiz_stills.yml")
POINTS = [ 5, 5, 5, 8, 8, 8, 12, 12, 15, 25 ].freeze
DURATIONS = [ 0, 0, 0, 20, 20, 20, 15, 15, 15, 15 ].freeze
INTENSITIES = [ 1, 1, 2, 2, 2, 3, 3, 4, 4, 5 ].freeze
LOCALES = %w[fr es en pt-BR].freeze
PSALM_LABELS = {
  "fr" => "Psaumes",
  "es" => "Salmos",
  "en" => "Psalms",
  "pt-BR" => "Salmos"
}.freeze
APPLICATION_CITES = {
  "fast-psalms-pack01-q09" => "Psaume 135:15-18 · Psaume 146:3-6",
  "fast-psalms-pack01-q10" => "Psaume 146:5-10"
}.freeze
ATMOSPHERE_MAP = {
  "contemplative" => "solemn",
  "dignified" => "peaceful",
  "enduring" => "peaceful",
  "expectant" => "dramatic",
  "hopeful" => "peaceful",
  "invitational" => "peaceful",
  "joyful" => "glorious",
  "jubilant" => "glorious",
  "majestic" => "glorious",
  "solemn" => "solemn",
  "welcoming" => "peaceful"
}.freeze
STILLS_BEGIN = "# BEGIN GENERATED PSALMS FAST RUNTIME STILLS"
STILLS_END = "# END GENERATED PSALMS FAST RUNTIME STILLS"

def fetch_hash(hash, *path)
  path.reduce(hash) { |value, key| value.fetch(key) }
end

def localized_questions(pack)
  french = fetch_hash(pack, "fast", "result", "quiz_final", "questions")
  translations = fetch_hash(pack, "fast", "result", "translations")
  { "fr" => french }.merge(
    %w[es en pt-BR].to_h { |locale| [ locale, fetch_hash(translations, locale, "questions") ] }
  )
end

def localized_cite(cite, locale)
  label = locale == "en" ? "Psalm" : "Salmo"
  plural = locale == "en" ? "Psalms" : "Salmos"
  return cite if locale == "fr"

  cite.gsub(/Psaumes\b/, plural).gsub(/Psaume\b/, label)
end

def psalm_number(cite)
  cite.match(/Psaumes?\s+(\d+)/)&.captures&.first ||
    raise("Cannot derive Psalm chapter from #{cite.inspect}")
end

def find_visual_metadata(value, concept_id)
  case value
  when Array
    value.each do |child|
      found = find_visual_metadata(child, concept_id)
      return found if found
    end
  when Hash
    if value["visual_concept_id"].to_s == concept_id.to_s &&
        (!value["celestial_family"].to_s.empty? || !value["theme"].to_s.empty?)
      return value
    end
    value.each_value do |child|
      found = find_visual_metadata(child, concept_id)
      return found if found
    end
  end
  nil
end

def still_theme(pack, review_unit, question_id)
  concept_id = review_unit["visual_concept_id"].to_s
  concept_id = question_id.sub(/\Afast-/, "").sub(/-q(\d+)\z/, "-visual-q\\1") if concept_id.empty?
  metadata = find_visual_metadata(fetch_hash(pack, "fast", "result"), concept_id) || {}
  mode = (metadata["celestial_family"] || metadata["theme"]).to_s.downcase
  mode = "light" unless %w[light dark].include?(mode)
  authored_atmosphere = metadata["atmosphere"].to_s.downcase
  atmosphere = ATMOSPHERE_MAP.fetch(authored_atmosphere, mode == "dark" ? "dramatic" : "peaceful")
  glass = metadata["glass"].to_s.downcase
  glass = "strong" unless %w[soft medium strong].include?(glass)
  { "mode" => mode, "atmosphere" => atmosphere, "glass" => glass }
end

manifest = YAML.safe_load_file(MANIFEST_PATH)
runtime = fetch_hash(manifest, "fast", "runtime_export")
cutover = fetch_hash(manifest, "fast", "runtime_cutover")
public_editorial = fetch_hash(manifest, "fast", "public_editorial")

raise "runtime cutover is not ready" unless %w[
  ready_for_runtime_export
  publication_authorized_awaiting_deployment
  deployed
].include?(cutover.fetch("status"))
raise "public editorial is not approved" unless public_editorial.fetch("status") == "approved"

pack_rows = manifest.fetch("packs")
pack_rows_by_id = pack_rows.to_h { |row| [ row.fetch("id"), row ] }
runtime_copy = runtime.fetch("pack_copy")
daily_copy = public_editorial.fetch("library_days")
stills = {}

packs = runtime.fetch("active_pack_ids").each_with_index.map do |pack_id, pack_index|
  copy_contract = runtime_copy.fetch(pack_id)
  source_pack_id = copy_contract.fetch("source_pack")
  source_row = pack_rows_by_id.fetch(source_pack_id)
  raise "#{source_pack_id} is not complete" unless source_row.fetch("status") == "complete_detached"

  pack_path = File.join(ROOT, source_row.fetch("path"))
  pack = YAML.safe_load_file(pack_path)
  raise "#{source_pack_id} French quiz is not approved" unless pack.dig("fast", "french_quiz_approval", "status") == "approved"
  raise "#{source_pack_id} translations are not approved" unless pack.dig("fast", "translation_approval", "status") == "approved"

  questions_by_locale = localized_questions(pack)
  french_questions = questions_by_locale.fetch("fr")
  raise "#{source_pack_id} must contain ten questions" unless french_questions.size == 10

  localized_by_id = questions_by_locale.transform_values do |questions|
    questions.to_h { |question| [ question.fetch("id"), question ] }
  end
  review_units = fetch_hash(pack, "fast", "french_quiz_approval", "review_units")
    .to_h { |unit| [ unit.fetch("question_id"), unit ] }

  questions = french_questions.each_with_index.map do |question, question_index|
    question_id = question.fetch("id")
    review_unit = review_units.fetch(question_id)
    choice_ids = question.fetch("choices").map { |choice| choice.fetch("id") }
    cite = [ review_unit["scripture_cite"], review_unit["displayed_scripture_cite"] ]
      .find { |value| !value.to_s.strip.empty? } ||
      APPLICATION_CITES[question_id] || question.fetch("reference")
    raise "#{question_id} still has an application placeholder" if cite == "application"

    copy = LOCALES.to_h do |locale|
      localized = localized_by_id.fetch(locale).fetch(question_id)
      localized_choice_ids = localized.fetch("choices").map { |choice| choice.fetch("id") }
      raise "#{question_id} #{locale} changes choice ids" unless localized_choice_ids == choice_ids
      raise "#{question_id} #{locale} changes correct choice" unless localized.fetch("correct_choice") == question.fetch("correct_choice")

      [ locale, {
        "prompt" => localized.fetch("prompt"),
        "choices" => localized.fetch("choices").map do |choice|
          { "key" => choice.fetch("id"), "label" => choice.fetch("text") }
        end,
        "feedback" => localized.fetch("feedback"),
        "scripture_cite" => localized_cite(cite, locale)
      } ]
    end

    source_image = File.join(ROOT, review_unit.fetch("image_path"))
    raise "missing approved image #{source_image}" unless File.file?(source_image)

    extension = File.extname(source_image).downcase
    target_relative = "media/quizzes/#{pack_id}/#{question_id}#{extension}"
    target_image = File.join(ROOT, "media/masters", target_relative)
    FileUtils.mkdir_p(File.dirname(target_image))
    FileUtils.cp(source_image, target_image) unless File.expand_path(source_image) == File.expand_path(target_image)
    presentation_path = "quizzes/#{pack_id}/#{question_id}#{extension}"
    stills[presentation_path] = still_theme(pack, review_unit, question_id)

    {
      "id" => question_id,
      "scripture" => {
        "canon" => "bible",
        "cite" => cite,
        "study" => "ot/ps/#{psalm_number(cite)}"
      },
      "correct_choice" => question.fetch("correct_choice"),
      "points" => POINTS.fetch(question_index),
      "duration" => DURATIONS.fetch(question_index),
      "intensity" => INTENSITIES.fetch(question_index),
      "presentation" => { "image" => presentation_path },
      "copy" => copy
    }
  end

  readings = pack.fetch("source").fetch("readings").map do |reading|
    chapter = psalm_number(reading.fetch("reference"))
    { "study" => "ot/ps/#{chapter}", "cite" => reading.fetch("reference") }
  end
  chapter_numbers = readings.map { |reading| reading.fetch("study").split("/").last }.uniq
  day = daily_copy.fetch(pack_index)
  pack_copy = LOCALES.to_h do |locale|
    [ locale, {
      "title" => copy_contract.fetch("title").fetch(locale),
      "kicker" => "#{PSALM_LABELS.fetch(locale)} #{chapter_numbers.join(' · ')}",
      "lede" => day.fetch("copy").fetch(locale).fetch("setup")
    } ]
  end

  {
    "id" => pack_id,
    "copy" => pack_copy,
    "readings" => readings,
    "questions" => questions
  }
end

output_path = File.join(ROOT, runtime.fetch("generated_catalog_path"))
FileUtils.mkdir_p(File.dirname(output_path))
File.write(output_path, YAML.dump({ "packs" => packs }).sub(/\A---\s*\n/, ""))

stills_lines = [ STILLS_BEGIN ]
stills.each do |path, theme|
  stills_lines << "  #{path}:"
  stills_lines << "    mode: #{theme.fetch('mode')}"
  stills_lines << "    atmosphere: #{theme.fetch('atmosphere')}"
  stills_lines << "    glass: #{theme.fetch('glass')}"
end
stills_lines << STILLS_END
stills_block = stills_lines.join("\n")

stills_source = File.read(STILLS_PATH)
generated_pattern = /^#{Regexp.escape(STILLS_BEGIN)}\n.*?^#{Regexp.escape(STILLS_END)}\n?/m
if stills_source.match?(generated_pattern)
  stills_source.sub!(generated_pattern, "#{stills_block}\n")
else
  marker = "# Generation prompts for the new parable collection."
  raise "quiz still insertion marker is missing" unless stills_source.include?(marker)

  stills_source.sub!(marker, "#{stills_block}\n\n#{marker}")
end
File.write(STILLS_PATH, stills_source)

pending_titles = runtime_copy.filter_map do |pack_id, contract|
  pack_id if contract.fetch("title_status") != "approved"
end
puts "Exported #{packs.size} active packs and #{packs.sum { |pack| pack.fetch('questions').size }} questions to #{output_path}."
puts "Copied approved quiz masters and registered #{stills.size} still themes."
puts "Preview-only titles awaiting human approval: #{pending_titles.join(', ')}" if pending_titles.any?
