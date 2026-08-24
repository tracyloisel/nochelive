#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate Noche Live challenge stills and clips via OpenRouter.
# Requires OPENROUTER_API_KEY.
#
#   ruby script/generate_chapel_media.rb --mode slides --only scavenger_harp,statue_david
#   ruby script/generate_chapel_media.rb --mode video --only david_goliath
#   ruby script/generate_chapel_media.rb --mode slides --all

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

WORLD_PATH = File.join(ROOT, "config/media/chapel_world.yml")
SHOTS_PATH = File.join(ROOT, "config/media/chapel_challenges.yml")
OUT_ROOT = File.join(ROOT, "public/media/challenges")
API = "https://openrouter.ai/api/v1"
IMAGE_MODEL = ENV.fetch("OPENROUTER_IMAGE_MODEL", "black-forest-labs/flux.2-flex")
VIDEO_MODEL = ENV.fetch("OPENROUTER_VIDEO_MODEL", "bytedance/seedance-2.0-mini")

def api_key
  key = ENV["OPENROUTER_API_KEY"].to_s.strip
  abort "OPENROUTER_API_KEY is missing. Export it, then rerun." if key.empty?

  key
end

def request(method, url, payload = nil, timeout: 180)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = timeout
  http.open_timeout = 20

  klass = { "GET" => Net::HTTP::Get, "POST" => Net::HTTP::Post }.fetch(method)
  req = klass.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"] = "application/json"
  req["HTTP-Referer"] = "https://noche.live"
  req["X-Title"] = "Noche Live chapel media"
  req.body = JSON.generate(payload) if payload

  res = http.request(req)
  body = res.body.to_s
  unless res.is_a?(Net::HTTPSuccess)
    raise OpenRouterError, "OpenRouter #{res.code} #{url}: #{body}"
  end

  body.empty? ? {} : JSON.parse(body)
end

class OpenRouterError < StandardError; end

def compose_prompt(world, room_key, shot)
  <<~PROMPT
    #{world.fetch("style").to_s.strip}

    SETTING: #{world.fetch(room_key).to_s.strip}

    PEOPLE: #{world.fetch("people").to_s.strip}

    SHOT: #{shot.to_s.strip}

    Avoid: #{world.fetch("negative").to_s.strip}
  PROMPT
end

def write_bytes(dest, bytes)
  FileUtils.mkdir_p(File.dirname(dest))
  File.binwrite(dest, bytes)
end

def generate_slide(prompt, dest)
  result = request("POST", "#{API}/images", {
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: "16:9",
    output_format: "jpeg"
  })
  first = Array(result["data"]).first
  abort "No image data: #{result.inspect[0, 400]}" unless first

  if first["b64_json"]
    raw = first["b64_json"]
    raw = raw.split(",", 2).last if raw.start_with?("data:")
    write_bytes(dest, Base64.decode64(raw))
    return
  end

  url = first["url"] || first.dig("image_url", "url")
  abort "No image url/b64: #{first.inspect[0, 400]}" unless url

  uri = URI(url)
  write_bytes(dest, Net::HTTP.get(uri))
end

def generate_video(prompt, dest)
  job = request("POST", "#{API}/videos", {
    model: VIDEO_MODEL,
    prompt: prompt,
    duration: 5,
    resolution: "720p",
    aspect_ratio: "16:9",
    generate_audio: false
  })
  job_id = job["id"]
  polling = job["polling_url"] || (job_id && "#{API}/videos/#{job_id}")
  abort "No polling url: #{job.inspect[0, 400]}" unless polling

  puts "  video job #{job_id} …"
  40.times do
    sleep 15
    status = request("GET", polling, timeout: 60)
    state = status["status"]
    puts "  #{state}"
    case state
    when "completed"
      content = Array(status["unsigned_urls"]).first || "#{API}/videos/#{job_id}/content?index=0"
      uri = URI(content)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 180
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{api_key}"
      res = http.request(req)
      abort "Download #{res.code}: #{res.body.to_s[0, 200]}" unless res.is_a?(Net::HTTPSuccess)
      write_bytes(dest, res.body)
      return
    when "failed", "cancelled", "expired"
      abort "Video #{state}: #{status["error"]}"
    end
  end
  abort "Video timed out"
end

mode = "slides"
only = nil
force = false
all = false

OptionParser.new do |opts|
  opts.on("--mode MODE", %w[slides video both]) { |value| mode = value }
  opts.on("--only IDS") { |value| only = value }
  opts.on("--all") { all = true }
  opts.on("--force") { force = true }
end.parse!

world = YAML.safe_load_file(WORLD_PATH)
shots = YAML.safe_load_file(SHOTS_PATH).fetch("rounds")
ids = if all || only.nil?
  shots.keys
else
  only.split(",").map(&:strip).reject(&:empty?)
end
unknown = ids - shots.keys
abort "Unknown rounds: #{unknown.join(", ")}" if unknown.any?

puts "image model=#{IMAGE_MODEL}"
puts "video model=#{VIDEO_MODEL}"
puts "rounds=#{ids.join(", ")}"

ids.each do |round_id|
  spec = shots.fetch(round_id)
  room = spec.fetch("room")
  folder = File.join(OUT_ROOT, round_id)
  puts "\n== #{round_id} (#{room}) =="

  if %w[slides both].include?(mode)
    spec.fetch("slides").each_with_index do |shot, index|
      dest = File.join(folder, "slides", format("%02d.jpg", index + 1))
      if File.exist?(dest) && !force
        puts "  skip #{dest.delete_prefix("#{ROOT}/")}"
        next
      end
      puts "  slide #{index + 1} …"
      begin
        generate_slide(compose_prompt(world, room, shot), dest)
        puts "  wrote #{dest.delete_prefix("#{ROOT}/")}"
      rescue OpenRouterError => error
        warn "  skip #{round_id} slide #{index + 1}: #{error.message[0, 240]}"
      end
    end
  end

  next unless %w[video both].include?(mode)

  dest = File.join(folder, "clip.mp4")
  if File.exist?(dest) && !force
    puts "  skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end
  generate_video(compose_prompt(world, room, spec.fetch("video")), dest)
  puts "  wrote #{dest.delete_prefix("#{ROOT}/")}"
end
