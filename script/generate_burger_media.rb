#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate El burger de fuego stills (16:9 Flux), Seedance clips, and garnish
# sprites via OpenRouter. Requires OPENROUTER_API_KEY.
#
#   ruby script/generate_burger_media.rb --all --force
#   ruby script/generate_burger_media.rb --only pan,lettuce

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
$stdout.sync = true
$stderr.sync = true

STORY_PATH = File.join(ROOT, "config/media/story_challenges.yml")
BURGER_PATH = File.join(ROOT, "config/media/burger.yml")
OUT_ROOT = File.join(ROOT, "public/media/burger")
API = "https://openrouter.ai/api/v1"
IMAGE_MODEL = ENV.fetch("OPENROUTER_IMAGE_MODEL", "black-forest-labs/flux.2-flex")
VIDEO_MODEL = ENV.fetch("OPENROUTER_VIDEO_MODEL", "bytedance/seedance-2.0-mini")
PAPER = "#f6f3ec"

def api_key
  key = ENV["OPENROUTER_API_KEY"].to_s.strip
  abort "OPENROUTER_API_KEY is missing. Export it, then rerun." if key.empty?

  key
end

class OpenRouterError < StandardError; end

def request(method, url, payload = nil, timeout: 180, retries: 4)
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
  req["X-Title"] = "Noche Live burger media"
  req.body = JSON.generate(payload) if payload

  res = http.request(req)
  body = res.body.to_s
  code = res.code.to_i
  unless res.is_a?(Net::HTTPSuccess)
    retryable = [429, 502, 503, 504].include?(code)
    raise OpenRouterError, "OpenRouter #{res.code} #{url}: #{body}" unless retryable && retries.positive?

    wait = code == 429 ? 60 : 8
    warn "  retry HTTP #{code} in #{wait}s"
    sleep wait
    return request(method, url, payload, timeout: timeout, retries: retries - 1)
  end

  body.empty? ? {} : JSON.parse(body)
rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => error
  raise OpenRouterError, "#{error.class}: #{error.message}" if retries <= 0

  wait = 45
  warn "  retry #{method} #{File.basename(uri.path)} after #{wait}s: #{error.class}"
  sleep wait
  request(method, url, payload, timeout: timeout, retries: retries - 1)
end

def wait_image_slot(flag)
  return unless flag

  puts "  pause 8s"
  sleep 8
end

def landscape_style(style)
  style.to_s.strip.gsub(/Vertical portrait composition\.?/i, "Wide 16:9 cinematic landscape composition.")
end

def sprite_style(style)
  style.to_s.strip.gsub(
    /Vertical portrait composition\.?/i,
    "Square isolated object on a flat cream paper background #{PAPER}."
  )
end

def compose_still_prompt(style, negative, scene)
  <<~PROMPT
    #{landscape_style(style)}

    SCENE: #{scene.to_s.strip}

    Avoid: #{negative.to_s.strip}
  PROMPT
end

def compose_clip_prompt(style, negative, scene, motion)
  <<~PROMPT
    #{landscape_style(style)}

    SCENE: #{scene.to_s.strip}

    MOTION: #{motion.to_s.strip}

    Avoid: #{negative.to_s.strip}
  PROMPT
end

def compose_sprite_prompt(style, negative, scene)
  <<~PROMPT
    #{sprite_style(style)}
    Single garnish sprite for a mix-blend overlay. Flat cream paper #{PAPER}, no drop shadow scene.

    SCENE: #{scene.to_s.strip}

    Avoid: #{negative.to_s.strip}, transparency checkerboard, photo cutout, 3D render
  PROMPT
end

def write_bytes(dest, bytes)
  FileUtils.mkdir_p(File.dirname(dest))
  File.binwrite(dest, bytes)
end

def data_url(path)
  bytes = File.binread(path)
  mime = bytes.start_with?("\x89PNG".b) ? "image/png" : "image/jpeg"
  "data:#{mime};base64,#{Base64.strict_encode64(bytes)}"
end

def save_image(dest, bytes, preferred_ext:)
  png = bytes.start_with?("\x89PNG".b)
  jpeg = bytes.start_with?("\xFF\xD8".b)
  ext = if png
    ".png"
  elsif jpeg
    ".jpg"
  else
    preferred_ext
  end
  path = dest.sub(/\.(png|jpe?g)\z/i, ext)
  write_bytes(path, bytes)
  path
end

def extract_image_bytes(result)
  first = Array(result["data"]).first
  raise OpenRouterError, "No image data: #{result.inspect[0, 400]}" unless first

  if first["b64_json"]
    raw = first["b64_json"]
    raw = raw.split(",", 2).last if raw.start_with?("data:")
    return Base64.decode64(raw)
  end

  url = first["url"] || first.dig("image_url", "url")
  raise OpenRouterError, "No image url/b64: #{first.inspect[0, 400]}" unless url

  Net::HTTP.get(URI(url))
end

def generate_still(prompt, dest)
  result = request("POST", "#{API}/images", {
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: "16:9",
    output_format: "jpeg"
  }, timeout: 480)
  save_image(dest, extract_image_bytes(result), preferred_ext: ".jpg")
end

def generate_sprite(prompt, dest)
  result = request("POST", "#{API}/images", {
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: "1:1",
    output_format: "png"
  }, timeout: 480)
  save_image(dest, extract_image_bytes(result), preferred_ext: ".png")
rescue OpenRouterError => error
  raise unless error.message.include?("400") || error.message.downcase.include?("png")

  warn "  png rejected, retrying jpeg: #{error.message[0, 180]}"
  result = request("POST", "#{API}/images", {
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: "1:1",
    output_format: "jpeg"
  }, timeout: 480)
  save_image(dest.sub(/\.png\z/i, ".jpg"), extract_image_bytes(result), preferred_ext: ".jpg")
end

def first_frame_supported?
  body = request("GET", "#{API}/videos/models", timeout: 30)
  list = if body.is_a?(Array)
    body
  else
    Array(body["data"] || body["models"] || body["items"])
  end
  entry = list.find do |model|
    ids = [model["id"], model["canonical_slug"], model["name"], model["model"]].compact
    ids.include?(VIDEO_MODEL)
  end
  return true if entry.nil?

  frames = entry["supported_frame_images"] || entry.dig("capabilities", "frame_images") || []
  names = Array(frames).map do |item|
    item.is_a?(Hash) ? (item["frame_type"] || item["type"] || item["id"]).to_s : item.to_s
  end
  names.empty? || names.include?("first_frame")
rescue OpenRouterError => error
  warn "  videos/models probe: #{error.message[0, 200]}"
  true
end

def download_video(url)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme != "http")
  http.read_timeout = 180
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  res = http.request(req)
  raise OpenRouterError, "Download #{res.code}: #{res.body.to_s[0, 200]}" unless res.is_a?(Net::HTTPSuccess)

  res.body
end

def video_content_url(status, job_id)
  Array(status["unsigned_urls"]).first ||
    status["url"] ||
    status.dig("video", "url") ||
    status.dig("assets", 0, "url") ||
    (job_id && "#{API}/videos/#{job_id}/content?index=0")
end

def submit_video(payload)
  request("POST", "#{API}/videos", payload, timeout: 180)
end

def generate_video(prompt, dest, still_path:, use_first_frame:)
  payload = {
    model: VIDEO_MODEL,
    prompt: prompt,
    duration: 5,
    resolution: "720p",
    aspect_ratio: "16:9",
    generate_audio: false
  }
  used_img2vid = false
  if use_first_frame && still_path && File.exist?(still_path)
    payload[:frame_images] = [{
      type: "image_url",
      image_url: { url: data_url(still_path) },
      frame_type: "first_frame"
    }]
    used_img2vid = true
  end

  begin
    job = submit_video(payload)
  rescue OpenRouterError => error
    if used_img2vid
      warn "  img2vid rejected, falling back to t2v: #{error.message[0, 240]}"
      payload.delete(:frame_images)
      used_img2vid = false
      job = submit_video(payload)
    else
      raise
    end
  end

  job_id = job["id"] || job["job_id"]
  polling = job["polling_url"] || (job_id && "#{API}/videos/#{job_id}")
  raise OpenRouterError, "No polling url: #{job.inspect[0, 400]}" unless polling

  puts "  video job #{job_id} (#{used_img2vid ? "img2vid" : "t2v"}) …"
  40.times do
    sleep 15
    status = request("GET", polling, timeout: 60)
    state = status["status"].to_s
    puts "  #{state.empty? ? "(no status)" : state}"
    case state
    when "completed", "complete", "succeeded", "success"
      content = video_content_url(status, job_id)
      raise OpenRouterError, "No video url: #{status.inspect[0, 400]}" unless content

      bytes = download_video(content)
      raise OpenRouterError, "Empty video download" if bytes.to_s.empty?

      write_bytes(dest, bytes)
      return used_img2vid
    when "failed", "cancelled", "canceled", "expired", "error"
      raise OpenRouterError, "Video #{state}: #{status["error"] || status.inspect[0, 300]}"
    end
  end
  raise OpenRouterError, "Video timed out"
end

only = nil
force = false
all = false

OptionParser.new do |opts|
  opts.on("--only IDS") { |value| only = value }
  opts.on("--all") { all = true }
  opts.on("--force") { force = true }
end.parse!

story = YAML.safe_load_file(STORY_PATH)
spec = YAML.safe_load_file(BURGER_PATH)
style = story.fetch("style")
negative = story.fetch("negative")
layers = spec.fetch("layers")
sprites = spec.fetch("sprites")
known = layers.keys + sprites.keys
ids = if all || only.nil?
  known
else
  only.split(",").map(&:strip).reject(&:empty?)
end
unknown = ids - known
abort "Unknown ids: #{unknown.join(", ")}" if unknown.any?

FileUtils.mkdir_p(OUT_ROOT)
puts "image model=#{IMAGE_MODEL}"
puts "video model=#{VIDEO_MODEL}"
puts "ids=#{ids.join(", ")}"
want_clips = ids.intersect?(layers.keys)
use_first_frame = want_clips && first_frame_supported?
puts "first_frame=#{use_first_frame ? "try" : "skip"}"

failures = []
rel = ->(path) { path.delete_prefix("#{ROOT}/") }
image_gap = false

ids.each do |id|
  if layers.key?(id)
    layer = layers.fetch(id)
    still_dest = File.join(OUT_ROOT, "#{id}.jpg")
    clip_dest = File.join(OUT_ROOT, "#{id}.mp4")

    if File.exist?(still_dest) && !force
      puts "skip #{rel.call(still_dest)}"
    else
      wait_image_slot(image_gap)
      puts "#{id} still …"
      begin
        written = generate_still(compose_still_prompt(style, negative, layer.fetch("still")), still_dest)
        puts "  wrote #{rel.call(written)}"
        still_dest = written
        image_gap = true
      rescue OpenRouterError => error
        warn "  FAIL still #{id}: #{error.message[0, 400]}"
        failures << ["#{id}.jpg", error.message]
        image_gap = true
      end
    end

    if File.exist?(clip_dest) && !force
      puts "skip #{rel.call(clip_dest)}"
    else
      puts "#{id} clip …"
      begin
        generate_video(
          compose_clip_prompt(style, negative, layer.fetch("still"), layer.fetch("motion")),
          clip_dest,
          still_path: still_dest,
          use_first_frame: use_first_frame && File.exist?(still_dest)
        )
        puts "  wrote #{rel.call(clip_dest)}"
      rescue OpenRouterError => error
        warn "  FAIL clip #{id}: #{error.message[0, 400]}"
        failures << ["#{id}.mp4", error.message]
        File.delete(clip_dest) if File.exist?(clip_dest) && File.size(clip_dest).zero?
      end
    end
  else
    png_dest = File.join(OUT_ROOT, "#{id}.png")
    jpg_dest = File.join(OUT_ROOT, "#{id}.jpg")
    existing = [png_dest, jpg_dest].find { |path| File.exist?(path) }
    if existing && !force
      puts "skip #{rel.call(existing)}"
      next
    end
    puts "#{id} sprite …"
    wait_image_slot(image_gap)
    begin
      written = generate_sprite(compose_sprite_prompt(style, negative, sprites.fetch(id)), png_dest)
      puts "  wrote #{rel.call(written)}"
      image_gap = true
    rescue OpenRouterError => error
      warn "  FAIL sprite #{id}: #{error.message[0, 400]}"
      failures << [id, error.message]
      image_gap = true
    end
  end
end

if failures.any?
  warn "\n#{failures.size} failed:"
  failures.each { |name, message| warn "  #{name}: #{message[0, 300]}" }
  abort "Burger media generation had failures."
end

puts "ok"
