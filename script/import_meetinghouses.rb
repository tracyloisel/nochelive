#!/usr/bin/env ruby
# frozen_string_literal: true

# Import listed congregaciones from the public Meetinghouse Locator.
# Never run from a web request or CI. Member directory is out of scope.
#
#   bin/rails noche:import_wards
#   bin/rails noche:import_wards FILE=test/fixtures/files/meetinghouses.json
#
# Optional: CHURCH_MAPS_TOKEN if the locator layer requires a bootstrap token.

require "json"
require "net/http"
require "uri"

ROOT = File.expand_path("..", __dir__)
LAYER_URL = "https://ws.churchofjesuschrist.org/ws/maps/v1.0/services/rest/layer/location"
MAPS_URL = "https://www.churchofjesuschrist.org/maps/meetinghouses/"
USER_AGENT = "NocheLive/1.0 (ward directory import; +https://github.com/tracyloisel/nochelive)"

def http_get(url, query = {})
  uri = URI(url)
  uri.query = URI.encode_www_form(query) if query.any?
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 120, open_timeout: 20) do |http|
    req = Net::HTTP::Get.new(uri)
    req["User-Agent"] = USER_AGENT
    req["Accept"] = "application/json, text/html;q=0.8"
    res = http.request(req)
    raise "Locator HTTP #{res.code} #{uri}" unless res.is_a?(Net::HTTPSuccess)

    res.body
  end
end

def bootstrap_token
  token = ENV["CHURCH_MAPS_TOKEN"].to_s.strip
  return token if token.present?

  html = http_get(MAPS_URL)
  html[/token=([A-Za-z0-9=+\-_]+)/, 1] || html[/"token"\s*:\s*"([^"]+)"/, 1]
end

def fetch_locator
  query = { locale: "en", layers: "meetinghouse", client: "mapsClient" }
  token = bootstrap_token
  query[:token] = token if token.present?
  JSON.parse(http_get(LAYER_URL, query))
end

file = ENV["FILE"].to_s.strip
ARGV.each { |arg| file = $1 if arg =~ /\A--file=(.*)\z/ }

payload = if file.present?
  JSON.parse(File.read(File.expand_path(file, ROOT)))
else
  fetch_locator
end

rows = Wards::ParseLocator.call(payload)
stats = Wards::SyncDirectory.call(rows: rows)
puts "wards import · created=#{stats[:created]} updated=#{stats[:updated]} skipped=#{stats[:skipped]} rows=#{rows.size}"
