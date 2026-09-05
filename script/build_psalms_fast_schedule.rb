#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../config/environment"
require "fileutils"
require "yaml"

ROOT = Rails.root
MANIFEST_PATH = ROOT.join("config/expeditions/psalms-102-150-fast.yml")
DEFAULT_OUTPUT = ROOT.join("tmp/psalms-fast-runtime/2026-08-31-psalms-102-150-fast.yml")
PACK_IDS = %w[
  psalms_living_god
  psalms_servant_king
  psalms_hears_knows
  psalms_walk_with_god
  psalms_build_home
  psalms_every_breath
].freeze
ARTWORK_KEYS = %w[
  scripture.library.daily.psalms-fast.ps136-mercy-refrain
  scripture.library.daily.psalms-fast.ps110-118-servant-king
  scripture.library.daily.psalms-fast.ps139-known
  scripture.library.daily.psalms-fast.ps119-lamp
  scripture.library.daily.psalms-fast.ps147-build-heal
  scripture.library.daily.psalms-fast.ps150-return
  scripture.library.daily.psalms-fast.ps110-118-weekly-contemplation
].freeze
DEPICTION_MODES = %w[
  biblical_illustration
  christian_interpretive_illustration
  contemporary_human_dramatization
  biblical_symbolic_illustration
  contemporary_human_dramatization
  contemporary_human_dramatization
  christian_interpretive_illustration
].freeze
CLAIM_IDS = [
  %w[fast-psalms-pack01-q03],
  %w[fast-psalms-pack02-q10],
  %w[fast-psalms-pack03-q10],
  %w[fast-psalms-pack04-q04],
  %w[fast-psalms-pack05-q10],
  %w[fast-psalms-pack06-q08],
  %w[
    fast-psalms-pack01-q03
    fast-psalms-pack02-q10
    fast-psalms-pack03-q10
    fast-psalms-pack04-q04
    fast-psalms-pack05-q10
    fast-psalms-pack06-q08
  ]
].freeze

output_path = ARGV.first ? ROOT.join(ARGV.first).cleanpath : DEFAULT_OUTPUT
allowed_output = output_path.to_s.start_with?(ROOT.join("tmp/psalms-fast-runtime").to_s) ||
  output_path == ROOT.join("config/study/library_daily_editorials/2026-08-31-psalms-102-150.yml")
raise "Output must be the FAST preview directory or the canonical Psalms schedule" unless allowed_output

manifest = YAML.safe_load_file(MANIFEST_PATH, aliases: false)
lifecycle = manifest.fetch("lifecycle")
revision = manifest.dig("lifecycle", "current_revision")
public_editorial = manifest.dig("fast", "public_editorial")
runtime = manifest.dig("fast", "runtime_export")
days = public_editorial.fetch("library_days")
accessibility = runtime.dig("accessibility_copy", "days").to_h { |day| [ day.fetch("day_id"), day ] }
fully_approved =
  runtime.dig("accessibility_copy", "status") == "approved" &&
  Array(runtime["unresolved_human_copy"]).empty? &&
  runtime.fetch("pack_copy").values.all? { |pack| pack.fetch("title_status") == "approved" } &&
  runtime.dig("library_editorial", "status") == "approved"
publication_state = fully_approved ? "publish_ready" : "draft"
human_gate_status = fully_approved ? "PASS" : "PENDING"
publication_authorized =
  fully_approved &&
  lifecycle.fetch("publish_authorized") == true &&
  runtime.fetch("publication_authorized") == true
publication_state = "scheduled" if publication_authorized

raise "FAST public editorial must be approved" unless public_editorial.fetch("status") == "approved"
raise "FAST schedule needs seven editorial days" unless days.size == 7
raise "FAST schedule needs seven accessibility entries" unless accessibility.size == 7
raise "FAST runtime pack ids changed" unless runtime.fetch("active_pack_ids") == PACK_IDS

discoveries = days.each_with_index.map do |day, index|
  day_id = day.fetch("id")
  accessibility_copy = accessibility.fetch(day_id)
  {
    "id" => day_id,
    "kind" => index == 6 ? "contemplation" : "discovery",
    "status" => "approved",
    "revision" => revision,
    "scheduled_on" => day.fetch("scheduled_on"),
    "timezone" => "Europe/Madrid",
    "pack_id" => index < 6 ? PACK_IDS.fetch(index) : nil,
    "reference" => day.fetch("reference"),
    "references" => day.fetch("references"),
    "claim_ids" => CLAIM_IDS.fetch(index),
    "artwork_key" => ARTWORK_KEYS.fetch(index),
    "light_family" => "celestial_light",
    "depiction_mode" => DEPICTION_MODES.fetch(index),
    "review_mode" => "fast",
    "motion" => "still",
    "audio" => "silent",
    "fast_gate" => { "status" => "PASS", "reviewed_revision" => revision },
    "copy" => day.fetch("copy"),
    "alt" => accessibility_copy.fetch("alt"),
    "disclosure" => accessibility_copy.fetch("disclosure")
  }.compact
end

discoveries_digest = StudyQuizVersion.content_digest_for(discoveries)
artwork_digest = Studies::DailyEditorialSchedule.artwork_digest_for(discoveries)
gates = %w[quiz_gate translation_gate public_editorial_gate visual_gate].to_h do |gate|
  [ gate, { "status" => "PASS", "reviewed_revision" => revision } ]
end
gates["human_gate"] = { "status" => human_gate_status, "reviewed_revision" => revision }

schedule = {
  "schema_version" => Studies::DailyEditorialSchedule::FAST_SCHEMA_VERSION,
  "id" => "library-2026-08-31-psalms-102-150-fast",
  "program_slug" => "come-follow-me-old-testament-2026-fr",
  "study_unit_slug" => "week-36",
  "starts_on" => "2026-08-31",
  "ends_on" => "2026-09-06",
  "timezone" => "Europe/Madrid",
  "source_dossier" => "config/expeditions/psalms-102-150-fast.yml",
  "publication" => {
    "state" => publication_state,
    "activate_at" => "2026-08-31T00:00:00+02:00"
  }.tap do |publication|
    next unless publication_authorized

    publication["authorized_by"] = runtime.fetch("publication_authorized_by")
    publication["authorized_on"] = runtime.fetch("publication_authorized_on")
  end,
  "expedition_pack_ids" => PACK_IDS,
  "expected_discoveries_digest" => discoveries_digest,
  "expected_artwork_digest" => artwork_digest,
  "fast_review" => {
    "revision" => revision,
    "publish_ready" => fully_approved
  }.merge(gates),
  "daily_discoveries" => discoveries
}

FileUtils.mkdir_p(output_path.dirname)
output_path.write(YAML.dump(schedule))

puts({
  output: output_path.relative_path_from(ROOT).to_s,
  revision:,
  discoveries_digest:,
  artwork_digest:,
  state: publication_state,
  human_gate: human_gate_status
}.inspect)
