#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate street-quiz stills (one gouache per question).
# Requires OPENROUTER_API_KEY.
#
#   ruby script/generate_quiz_media.rb --only coronas
#   ruby script/generate_quiz_media.rb --only coronas/ungio_david
#   ruby script/generate_quiz_media.rb --only coronas,placas
#   ruby script/generate_quiz_media.rb --all --force
#
# Writes public/media/quizzes/<pack>/<id>.jpg — never public/media/stories/.

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

SHOTS_PATH = File.join(ROOT, "config/media/quiz_stills.yml")
WORLD_PATH = File.join(ROOT, "config/media/street_world.yml")
OUT_ROOT = File.join(ROOT, "public/media/quizzes")
API = "https://openrouter.ai/api/v1"
IMAGE_MODEL = ENV.fetch("OPENROUTER_IMAGE_MODEL", "black-forest-labs/flux.2-flex")
STORIES_ROOT = File.join(ROOT, "public/media/stories")

def api_key
  key = ENV["OPENROUTER_API_KEY"].to_s.strip
  abort "OPENROUTER_API_KEY is missing. Export it, then rerun." if key.empty?

  key
end

class OpenRouterError < StandardError; end

def request(url, payload, timeout: 900, retries: 2)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = timeout
  http.open_timeout = 20
  http.keep_alive_timeout = timeout

  req = Net::HTTP::Post.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"] = "application/json"
  req["HTTP-Referer"] = "https://noche.live"
  req["X-Title"] = "Noche Live quiz media"
  req.body = JSON.generate(payload)

  res = http.request(req)
  body = res.body.to_s
  unless res.is_a?(Net::HTTPSuccess)
    retryable = retries.positive? && %w[429 502 503 504].include?(res.code)
    raise OpenRouterError, "OpenRouter #{res.code}: #{body}" unless retryable

    wait = res.code == "429" ? 90 : 15
    warn "  retry HTTP #{res.code} in #{wait}s"
    sleep wait
    return request(url, payload, timeout: timeout, retries: retries - 1)
  end

  body.empty? ? {} : JSON.parse(body)
rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => error
  raise OpenRouterError, "#{error.class}: #{error.message}" if retries <= 0

  wait = 90
  warn "  retry after #{wait}s: #{error.class}"
  sleep wait
  request(url, payload, timeout: timeout, retries: retries - 1)
end

def compose_prompt(world, shot)
  style = world.fetch("style").to_s.strip
  adventure = world["adventure"].to_s.strip
  people = world["people"].to_s.strip
  negative = world.fetch("negative").to_s.strip

  <<~PROMPT
    #{style}

    #{("ADVENTURE: #{adventure}" if !adventure.to_s.strip.empty?)}

    #{("PEOPLE: #{people}" if !people.to_s.strip.empty?)}

    SCENE: #{shot.to_s.strip}

    Avoid: #{negative}
  PROMPT
end

def generate_still(prompt, dest)
  abort "Refusing to write into public/media/stories/" if dest.start_with?(STORIES_ROOT)

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

def resolve_targets(packs, only, all)
  if all || only.nil?
    return packs.flat_map do |pack_id, questions|
      questions.keys.map { |qid| [pack_id, qid] }
    end
  end

  targets = []
  only.split(",").map(&:strip).reject(&:empty?).each do |token|
    if token.include?("/")
      pack_id, qid = token.split("/", 2)
      abort "Unknown pack: #{pack_id}" unless packs.key?(pack_id)
      abort "Unknown still: #{token}" unless packs.fetch(pack_id).key?(qid)
      targets << [pack_id, qid]
    else
      abort "Unknown pack: #{token}" unless packs.key?(token)
      packs.fetch(token).each_key { |qid| targets << [token, qid] }
    end
  end
  targets
end

only = nil
force = false
all = false

OptionParser.new do |opts|
  opts.on("--only IDS") { |value| only = value }
  opts.on("--all") { all = true }
  opts.on("--force") { force = true }
end.parse!

world = YAML.safe_load_file(WORLD_PATH)
spec = YAML.safe_load_file(SHOTS_PATH)
packs = spec.fetch("packs")
puts "world=#{WORLD_PATH.delete_prefix("#{ROOT}/")}"
targets = resolve_targets(packs, only, all)
abort "No stills to generate." if targets.empty?

puts "image model=#{IMAGE_MODEL}"
puts "shots=#{targets.map { |pack_id, qid| "#{pack_id}/#{qid}" }.join(", ")}"

targets.each do |pack_id, qid|
  dest = File.join(OUT_ROOT, pack_id, "#{qid}.jpg")
  abort "Refusing to write into public/media/stories/" if dest.start_with?(STORIES_ROOT)
  if File.exist?(dest) && !force
    puts "skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end
  puts "#{pack_id}/#{qid} …"
  begin
    generate_still(compose_prompt(world, packs.fetch(pack_id).fetch(qid)), dest)
    puts "  wrote #{dest.delete_prefix("#{ROOT}/")}"
  rescue OpenRouterError => error
    if error.message.include?("402")
      abort error.message
    end
    warn "  skip #{pack_id}/#{qid}: #{error.message[0, 180]}"
  end
end
