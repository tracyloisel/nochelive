#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

ROOT = File.expand_path("..", __dir__)
SOURCE = File.join(ROOT, "config/expeditions/fragments/psalms-102-150-2026-08-31-quiz-packs.fr.yml")
TARGET = File.join(ROOT, "config/quizzes/expedition_psalms_2026.yml")

PACK_COPY = {
  "disappearing-voice" => ["La voix qui disparaît", "Psaumes 102–103", "Quand tes jours partent en fumée, qu’est-ce qui peut encore tenir ?"],
  "nameless-king" => ["Le Roi sans nom", "Psaume 110", "Un roi reçoit une promesse étrange : prêtre pour toujours."],
  "cry-stone-seek" => ["Cherche-moi", "Psaumes 116–119", "Crier, traverser la porte et demander à Dieu de venir te chercher."],
  "house-table-city" => ["La maison que Dieu bâtit", "Psaumes 127–128", "Travailler, aimer et bâtir sans porter seul le poids du monde."],
  "suspended-harps" => ["Les harpes suspendues", "Psaumes 135–139", "Ils ont détruit leur ville, puis leur ont demandé de la chanter."],
  "everything-breathes" => ["Tout ce qui respire", "Psaumes 146–150", "Le Dieu qui compte les étoiles s’arrête devant les cœurs brisés."],
}.freeze

PACK_READINGS = {
  "disappearing-voice" => [102, 103],
  "nameless-king" => [110],
  "cry-stone-seek" => [116, 117, 118, 119],
  "house-table-city" => [127, 128],
  "suspended-harps" => [135, 136, 137, 138, 139],
  "everything-breathes" => [146, 147, 148, 149, 150],
}.freeze

CURVE_POINTS = [5, 5, 5, 8, 8, 8, 12, 12, 15, 25].freeze
CURVE_DURATION = [0, 0, 0, 20, 20, 20, 15, 15, 15, 15].freeze
CURVE_INTENSITY = [1, 1, 2, 2, 2, 3, 3, 4, 4, 5].freeze

def study_path(reference)
  chapter = reference.to_s[/Psaumes?\s+(\d+)/, 1]
  raise "Missing Psalm chapter in #{reference.inspect}" unless chapter

  "ot/ps/#{chapter}"
end

source = YAML.safe_load_file(SOURCE)
items = source.fetch("formation_quizzes").fetch("items")
packs = items.group_by { |item| item.fetch("pack_id") }.map do |pack_id, questions|
  title, kicker, lede = PACK_COPY.fetch(pack_id)
  raise "#{pack_id} must contain 10 questions" unless questions.size == 10

  {
    "id" => "exp_psalms_#{pack_id.tr('-', '_')}",
    "title" => title,
    "kicker" => kicker,
    "lede" => lede,
    "readings" => PACK_READINGS.fetch(pack_id).map { |chapter| { "study" => "ot/ps/#{chapter}", "cite" => "Psaume #{chapter}" } },
    "questions" => questions.each_with_index.map do |item, index|
      reference = item.fetch("scripture_references").first
      question_id = item.fetch("id").tr("-", "_")
      {
        "id" => question_id,
        "question" => item.fetch("prompt"),
        "choices" => item.fetch("choices").map { |choice| { "key" => choice.fetch("id"), "label" => choice.fetch("text") } },
        "correct_choice" => item.fetch("correct_choice"),
        "answer" => item.fetch("correction"),
        "points" => CURVE_POINTS.fetch(index),
        "duration" => CURVE_DURATION.fetch(index),
        "intensity" => CURVE_INTENSITY.fetch(index),
        "scripture" => { "canon" => "bible", "cite" => reference, "study" => study_path(reference) },
        "presentation" => { "image" => "quizzes/exp_psalms_#{pack_id.tr('-', '_')}/#{question_id}.png" },
      }
    end,
  }
end

File.write(TARGET, { "packs" => packs }.to_yaml(line_width: -1))
puts "wrote #{TARGET} · packs=#{packs.size} questions=#{packs.sum { |pack| pack.fetch('questions').size }}"
