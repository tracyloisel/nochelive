#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate biblical story stills for presenter + watch.
# Requires OPENROUTER_API_KEY.
#
#   ruby script/generate_story_media.rb --only salomon_wisdom,rey_o_profeta
#   ruby script/generate_story_media.rb --all --force

require "base64"
require "fileutils"
require "json"
require "net/http"
require "optparse"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)

def load_dotenv
  path = File.join(ROOT, ".env")
  return unless File.exist?(path)

  File.readlines(path, chomp: true).each do |line|
    next if line.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    next unless key && value

    ENV[key.strip] ||= value.strip.sub(/\A["']/, "").sub(/["']\z/, "")
  end
end

load_dotenv

SHOTS_PATH = File.join(ROOT, "config/media/story_challenges.yml")
OUT_ROOT = File.join(ROOT, "public/media/stories")
API = "https://openrouter.ai/api/v1"
IMAGE_MODEL = ENV.fetch("OPENROUTER_IMAGE_MODEL", "black-forest-labs/flux.2-flex")

def api_key
  key = ENV["OPENROUTER_API_KEY"].to_s.strip
  abort "OPENROUTER_API_KEY is missing. Export it, then rerun." if key.empty?

  key
end

class OpenRouterError < StandardError; end

def request(url, payload, timeout: 180)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = timeout
  http.open_timeout = 20

  req = Net::HTTP::Post.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"] = "application/json"
  req["HTTP-Referer"] = "https://noche.live"
  req["X-Title"] = "Noche Live story media"
  req.body = JSON.generate(payload)

  res = http.request(req)
  body = res.body.to_s
  raise OpenRouterError, "OpenRouter #{res.code}: #{body}" unless res.is_a?(Net::HTTPSuccess)

  body.empty? ? {} : JSON.parse(body)
end

def compose_prompt(spec, shot)
  <<~PROMPT
    #{spec.fetch("style").to_s.strip}

    SCENE: #{shot.to_s.strip}

    Avoid: #{spec.fetch("negative").to_s.strip}
  PROMPT
end

def generate_still(prompt, dest)
  result = request("#{API}/images", {
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: "9:16",
    output_format: "jpeg"
  })
  first = Array(result["data"]).first
  abort "No image data: #{result.inspect[0, 400]}" unless first

  if first["b64_json"]
    raw = first["b64_json"]
    raw = raw.split(",", 2).last if raw.start_with?("data:")
    FileUtils.mkdir_p(File.dirname(dest))
    File.binwrite(dest, Base64.decode64(raw))
    return
  end

  url = first["url"] || first.dig("image_url", "url")
  abort "No image url/b64: #{first.inspect[0, 400]}" unless url

  FileUtils.mkdir_p(File.dirname(dest))
  File.binwrite(dest, Net::HTTP.get(URI(url)))
end

only = nil
force = false
all = false

OptionParser.new do |opts|
  opts.on("--only IDS") { |value| only = value }
  opts.on("--all") { all = true }
  opts.on("--force") { force = true }
end.parse!

spec = YAML.safe_load_file(SHOTS_PATH)
shots = spec.fetch("rounds")
ids = if all || only.nil?
  shots.keys
else
  only.split(",").map(&:strip).reject(&:empty?)
end
unknown = ids - shots.keys
abort "Unknown rounds: #{unknown.join(", ")}" if unknown.any?

puts "image model=#{IMAGE_MODEL}"
puts "rounds=#{ids.join(", ")}"

ids.each do |round_id|
  dest = File.join(OUT_ROOT, "#{round_id}.jpg")
  if File.exist?(dest) && !force
    puts "skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end
  puts "#{round_id} …"
  generate_still(compose_prompt(spec, shots.fetch(round_id)), dest)
  puts "  wrote #{dest.delete_prefix("#{ROOT}/")}"
end
