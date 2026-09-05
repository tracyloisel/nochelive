#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "yaml"

ROOT = File.expand_path("..", __dir__)
POINTS = [ 5, 5, 5, 8, 8, 8, 12, 12, 15, 25 ].freeze
DURATIONS = [ 0, 0, 0, 20, 20, 20, 15, 15, 15, 15 ].freeze
INTENSITIES = [ 1, 1, 2, 2, 2, 3, 3, 4, 4, 5 ].freeze

source_path = File.expand_path(ARGV.fetch(0), ROOT)
dossier = YAML.safe_load_file(source_path)
runtime = dossier.fetch("runtime_export")
raise "runtime export is not authorized" unless runtime.fetch("status") == "authorized"
raise "French quiz is not approved" unless dossier.dig("fast", "french_quiz_approval", "status") == "approved"
raise "translations are not approved" unless dossier.dig("fast", "translation_approval", "status") == "approved"

pack_metadata = runtime.fetch("pack")
pack_id = pack_metadata.fetch("id")
output_path = File.expand_path(pack_metadata.fetch("catalog_file"), ROOT)
french_questions = dossier.dig("fast", "result", "quiz_final", "questions").to_a
translations = dossier.dig("fast", "result", "translations", "locales").to_h
localized_questions = { "fr" => french_questions }.merge(
  translations.transform_values { |locale| locale.fetch("questions") }
)
expected_locales = pack_metadata.fetch("copy").keys
raise "runtime copy and question locales differ" unless localized_questions.keys.sort == expected_locales.sort
raise "FAST pack must contain ten questions" unless french_questions.size == 10

localized_by_id = localized_questions.transform_values do |questions|
  questions.each_with_object({}) { |question, index| index[question.fetch("id")] = question }
end
review_units = dossier.dig("fast", "french_quiz_approval", "review_units").to_a.each_with_object({}) do |unit, index|
  index[unit.fetch("question_id")] = unit
end

questions = french_questions.each_with_index.map do |question, index|
  question_id = question.fetch("id")
  choice_ids = question.fetch("choices").map { |choice| choice.fetch("id") }
  copy = localized_by_id.to_h do |locale, rows|
    localized = rows.fetch(question_id)
    localized_choice_ids = localized.fetch("choices").map { |choice| choice.fetch("id") }
    raise "#{question_id} #{locale} changes choice ids" unless localized_choice_ids == choice_ids
    raise "#{question_id} #{locale} changes correct choice" unless localized.fetch("correct_choice") == question.fetch("correct_choice")

    [ locale, {
      "prompt" => localized.fetch("prompt"),
      "choices" => localized.fetch("choices").map { |choice| { "key" => choice.fetch("id"), "label" => choice.fetch("text") } },
      "feedback" => localized.fetch("feedback")
    } ]
  end

  source_image = File.expand_path(review_units.fetch(question_id).fetch("image_path"), ROOT)
  raise "missing approved image #{source_image}" unless File.file?(source_image)

  image_extension = File.extname(source_image).downcase
  target_relative = "media/quizzes/#{pack_id}/#{question_id}#{image_extension}"
  target_image = File.join(ROOT, "media/masters", target_relative)
  FileUtils.mkdir_p(File.dirname(target_image))
  FileUtils.cp(source_image, target_image)

  reference = question.fetch("reference")
  cite = reference == "application" ? "D&A 89" : reference
  {
    "id" => question_id,
    "scripture" => { "canon" => "dc", "cite" => cite, "study" => "dc-testament/dc/89" },
    "correct_choice" => question.fetch("correct_choice"),
    "points" => POINTS.fetch(index),
    "duration" => DURATIONS.fetch(index),
    "intensity" => INTENSITIES.fetch(index),
    "presentation" => { "image" => "quizzes/#{pack_id}/#{question_id}#{image_extension}" },
    "copy" => copy
  }
end

payload = {
  "packs" => [ {
    "id" => pack_id,
    "copy" => pack_metadata.fetch("copy"),
    "readings" => [ { "study" => "dc-testament/dc/89", "cite" => "D&A 89" } ],
    "questions" => questions
  } ]
}

FileUtils.mkdir_p(File.dirname(output_path))
File.write(output_path, YAML.dump(payload).sub(/\A---\s*\n/, ""))
puts "Exported #{pack_id} to #{output_path} with #{questions.size} questions."
