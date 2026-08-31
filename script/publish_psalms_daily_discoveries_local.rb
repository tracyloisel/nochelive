#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../config/environment"
require "json"
require "yaml"

abort "This publisher is local-only." unless Rails.env.local?

path = Rails.root.join("config/study/psalms_daily_discoveries_2026.yml")
data = YAML.safe_load_file(path, aliases: false)
starts_on = Date.iso8601(data.fetch("starts_on"))
ends_on = Date.iso8601(data.fetch("ends_on"))

program = StudyProgram.find_by!(slug: data.fetch("program_slug"))
unit = program.study_units.find_by!(
  slug: data.fetch("study_unit_slug"),
  starts_on:,
  ends_on:
)
source = unit.published_quiz
raise "The configured study week has no published quiz version." unless source

expected_pack_ids = data.fetch("expedition_pack_ids")
unless source.expedition_pack_ids == expected_pack_ids
  raise "The published expedition packs no longer match the reviewed daily edition."
end

published = Studies::PublishDailyDiscoveries.call(
  study_unit: unit,
  discoveries: data.fetch("daily_discoveries"),
  expected_discoveries_digest: data.fetch("expected_discoveries_digest"),
  at: Time.current
)

puts JSON.pretty_generate(
  study_unit_id: unit.id,
  quiz_version_id: published.id,
  version: published.version,
  content_digest: published.content_digest,
  daily_discoveries: published.daily_discoveries.map { |row| row.slice("id", "scheduled_on", "reference") }
)
