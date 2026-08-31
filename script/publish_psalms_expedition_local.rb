#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../config/environment"
require "digest"
require "yaml"

FRAGMENT = Rails.root.join("config/expeditions/fragments/psalms-102-150-2026-08-31-quiz-packs.fr.yml")
PACK_IDS = %w[
  exp_psalms_disappearing_voice
  exp_psalms_nameless_king
  exp_psalms_cry_stone_seek
  exp_psalms_house_table_city
  exp_psalms_suspended_harps
  exp_psalms_everything_breathes
].freeze

READINGS = [102, 103, 110, 116, 117, 118, 119, 127, 128, 135, 136, 137, 138, 139, 146, 147, 148, 149, 150].map do |chapter|
  { "study" => "ot/ps/#{chapter}", "labels" => { "fr" => "Psaume #{chapter}" } }
end.freeze

ward = Ward.find_by!(name: "Rama Benidorm")
player = Person.find(22)
raise "Player 22 is not in Rama Benidorm" unless player.ward_id == ward.id

unit = StudyUnit.find_by!(starts_on: Date.new(2026, 8, 31), ends_on: Date.new(2026, 9, 6))
fragment = YAML.safe_load_file(FRAGMENT)
first_pack = fragment.fetch("formation_quizzes").fetch("items").select { |item| item.fetch("pack_id") == "disappearing-voice" }
raise "Home pack must contain ten questions" unless first_pack.size == 10

questions = first_pack.map do |item|
  {
    "key" => item.fetch("id").tr("-", "_"),
    "locales" => {
      "fr" => {
        "question" => item.fetch("prompt"),
        "choices" => item.fetch("choices").to_h { |choice| [choice.fetch("id"), choice.fetch("text")] },
        "explanation" => item.fetch("correction"),
      },
    },
    "scripture_ref" => item.fetch("scripture_references").first,
    "correct_choice" => item.fetch("correct_choice"),
  }
end

content = {
  "key" => "ils-ont-crie-vers-dieu-2026",
  "light" => { "fr" => "Le Dieu qui me connaît et me relève est digne de toute ma louange." },
  "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
  "ceremony_artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
  "readings" => READINGS,
  "questions" => questions,
}

StudyQuizVersion.transaction do
  unit.update!(
    status: "published",
    copy: unit.copy.deep_merge(
      "fr" => {
        "title" => "31 août – 6 septembre : Ils ont crié vers Dieu",
        "theme" => "Quand il ne reste que la foi",
        "scripture_refs" => READINGS.map { |reading| reading.dig("labels", "fr") },
      }
    )
  )
  unit.study_quiz_versions.where(status: "published").where.not(version: 2).update_all(status: "retired")
  version = unit.study_quiz_versions.find_or_initialize_by(version: 2)
  version.update!(
    status: "published",
    editorial_locale: "fr",
    content:,
    content_digest: Digest::SHA256.hexdigest(content.to_json),
    published_at: Time.current
  )
end

zone = Time.find_zone!("Europe/Madrid")
schedules = [
  [zone.local(2026, 8, 31, 20, 0), PACK_IDS.first(3)],
  [zone.local(2026, 9, 4, 20, 0), PACK_IDS.last(3)],
]

nights = schedules.map do |starts_at, quiz_ids|
  night = GameSession.find_by(ward:, starts_at:)
  if night
    Nights::Configure.call(night:, attributes: { quiz_pack_ids: quiz_ids }) if night.quiz_pack_ids != quiz_ids
    night.reload
  else
    Nights::Start.call(ward:, quiz_ids:, starts_at:)
  end
end

puts({
  expedition: { study_unit_id: unit.id, quiz_version: 2, starts_on: unit.starts_on, ends_on: unit.ends_on },
  player: { id: player.id, name: player.display_name, ward: ward.name },
  nights: nights.map { |night| { id: night.id, code: night.code, starts_at: night.starts_at.in_time_zone(zone), quiz_pack_ids: night.quiz_pack_ids } },
}.inspect)
