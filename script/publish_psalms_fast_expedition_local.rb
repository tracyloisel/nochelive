#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../config/environment"
require "yaml"

ROOT = Rails.root
MANIFEST_PATH = ROOT.join("config/expeditions/psalms-102-150-fast.yml")
SCHEDULE_PATH = ROOT.join("config/study/library_daily_editorials/2026-08-31-psalms-102-150.yml")
RAMA_ARTWORK_KEY = "expedition.psalms-102-150-fast.rama-weekly-hero"
EXPEDITION_ARTWORK = "media/expeditions/psalms-102-150-fast/ps110-118-roi-serviteur-portrait-v1.png"

manifest = YAML.safe_load_file(MANIFEST_PATH, aliases: false)
lifecycle = manifest.fetch("lifecycle")
runtime = manifest.dig("fast", "runtime_export")
cutover = manifest.dig("fast", "runtime_cutover")
public_editorial = manifest.dig("fast", "public_editorial")
schedule = Studies::DailyEditorialSchedule.load(SCHEDULE_PATH).validate!

raise "manifest publication is not authorized" unless lifecycle.fetch("publish_authorized") == true
raise "runtime publication is not authorized" unless runtime.fetch("publication_authorized") == true
raise "cutover strategy changed" unless cutover.fetch("strategy") == "replace_visible_preserve_history"
raise "FAST accessibility copy is not approved" unless runtime.dig("accessibility_copy", "status") == "approved"
raise "FAST runtime copy still has unresolved decisions" unless Array(runtime["unresolved_human_copy"]).empty?
raise "FAST Library editorial is not approved" unless runtime.dig("library_editorial", "status") == "approved"
raise "FAST schedule is not human-scheduled" unless schedule.scheduled?
raise "FAST human gate did not pass" unless schedule.fast_review.dig("human_gate", "status") == "PASS"

pack_ids = runtime.fetch("active_pack_ids")
raise "FAST catalog pack ids do not match the schedule" unless pack_ids == schedule.expedition_pack_ids
pack_ids.each { |pack_id| QuizDefinition.catalog.find_pack(pack_id) }

readings = manifest.fetch("source").fetch("readings").filter_map do |reading|
  reference = reading.fetch("reference")
  chapter = reference.match(/\APsaume\s+(\d+)\z/)&.captures&.first
  next unless chapter

  {
    "study" => "ot/ps/#{chapter}",
    "labels" => {
      "fr" => "Psaume #{chapter}",
      "es" => "Salmo #{chapter}",
      "en" => "Psalm #{chapter}",
      "pt-BR" => "Salmo #{chapter}"
    }
  }
end

artwork_digest = Expeditions::RamaHero.artwork_digest_for(RAMA_ARTWORK_KEY)
expedition_copy = public_editorial.fetch("expedition")
content = {
  "key" => "psalms-102-150-fast-2026",
  "light" => expedition_copy.fetch("promise"),
  "artwork" => EXPEDITION_ARTWORK,
  "ceremony_artwork" => EXPEDITION_ARTWORK,
  "readings" => readings,
  "questions" => [],
  "daily_discoveries" => schedule.discoveries,
  "expedition" => {
    "id" => "psalms-102-150-fast-2026-08-31",
    "title" => expedition_copy.fetch("title"),
    "subtitle" => expedition_copy.fetch("subtitle"),
    "promise" => expedition_copy.fetch("promise"),
    "structure_type" => "constellation",
    "artwork" => EXPEDITION_ARTWORK,
    "pack_ids" => pack_ids,
    "packs" => pack_ids.map { |pack_id| { "id" => pack_id } },
    "rama_hero" => {
      "revision" => lifecycle.fetch("current_revision"),
      "headline" => public_editorial.fetch("rama_headline"),
      "artwork_key" => RAMA_ARTWORK_KEY,
      "light_family" => "celestial_light",
      "artwork_digest" => artwork_digest
    }
  }
}
content_digest = StudyQuizVersion.content_digest_for(content)

unit = StudyProgram.find_by!(slug: schedule.program_slug).study_units.find_by!(
  slug: schedule.study_unit_slug,
  starts_on: schedule.starts_on,
  ends_on: schedule.ends_on
)

published = StudyQuizVersion.transaction do
  unit.lock!
  existing = unit.study_quiz_versions.lock.find_by(content_digest:)
  if existing&.status == "published"
    next existing
  elsif existing && existing.status != "needs_review"
    raise "matching immutable version is not reviewable"
  end

  conflicting_review = unit.study_quiz_versions
    .where(status: "needs_review")
    .where.not(id: existing&.id)
    .exists?
  raise "study unit already has a different version in review" if conflicting_review

  candidate = existing || unit.study_quiz_versions.create!(
    version: unit.study_quiz_versions.maximum(:version).to_i + 1,
    status: "needs_review",
    editorial_locale: "fr",
    content:,
    content_digest:
  )
  Studies::PublishQuizVersion.call(
    version: candidate,
    expected_content_digest: content_digest,
    at: Time.current
  )
end

puts({
  study_unit_id: unit.id,
  quiz_version_id: published.id,
  version: published.version,
  status: published.status,
  content_digest: published.content_digest,
  active_pack_ids: pack_ids,
  archived_pack_ids: QuizDefinition.catalog.archived_pack_ids
}.inspect)
