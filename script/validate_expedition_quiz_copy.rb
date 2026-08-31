# frozen_string_literal: true

require "yaml"

path = ARGV.fetch(0) do
  warn "Usage: ruby script/validate_expedition_quiz_copy.rb PATH"
  exit 2
end

document = YAML.load_file(path)
quizzes = document.fetch("formation_quizzes")
limits = quizzes.fetch("copy_limits")

prompt_max = limits.dig("prompt", "hard_max")
choice_max = limits.dig("choice", "hard_max")
correction_max = limits.dig("correction", "hard_max")
choices_max = limits.fetch("max_choices")

graphemes = ->(copy) { copy.to_s.scan(/\X/).length }
errors = []

quizzes.fetch("items").each do |question|
  id = question.fetch("id")
  prompt_length = graphemes.call(question.fetch("prompt"))
  correction_length = graphemes.call(question.fetch("correction"))
  choices = question.fetch("choices")

  errors << "#{id}: prompt #{prompt_length}/#{prompt_max}" if prompt_length > prompt_max
  errors << "#{id}: correction #{correction_length}/#{correction_max}" if correction_length > correction_max
  errors << "#{id}: choices #{choices.length}/#{choices_max}" if choices.length > choices_max

  choices.each do |choice|
    choice_length = graphemes.call(choice.fetch("text"))
    errors << "#{id}.#{choice.fetch("id")}: choice #{choice_length}/#{choice_max}" if choice_length > choice_max
  end

  metrics = question["copy_metrics"]
  next unless metrics

  errors << "#{id}: stale prompt metric" unless metrics["prompt_graphemes"] == prompt_length
  errors << "#{id}: stale correction metric" unless metrics["correction_graphemes"] == correction_length

  choices.each do |choice|
    recorded = metrics.dig("choice_graphemes", choice.fetch("id"))
    actual = graphemes.call(choice.fetch("text"))
    errors << "#{id}.#{choice.fetch("id")}: stale choice metric" unless recorded == actual
  end
end

if errors.any?
  warn "REJECT_COPY_OVERFLOW"
  errors.each { |error| warn "- #{error}" }
  exit 1
end

puts "MOBILE COPY GATE PASS — #{quizzes.fetch("items").length} questions"
