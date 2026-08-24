#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate team emblems, round icons, and player avatars via OpenRouter.
#
#   ruby script/generate_marks.rb
#   ruby script/generate_marks.rb --only emblems
#   ruby script/generate_marks.rb --only avatars --force

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

SPEC_PATH = File.join(ROOT, "config/media/marks.yml")
OUT_ROOT = File.join(ROOT, "public/marks")
API = "https://openrouter.ai/api/v1"
IMAGE_MODEL = ENV.fetch("OPENROUTER_IMAGE_MODEL", "black-forest-labs/flux.2-flex")

class OpenRouterError < StandardError; end

def api_key
  key = ENV["OPENROUTER_API_KEY"].to_s.strip
  abort "OPENROUTER_API_KEY is missing." if key.empty?

  key
end

def request(payload)
  uri = URI("#{API}/images")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 180
  http.open_timeout = 20
  req = Net::HTTP::Post.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"] = "application/json"
  req["HTTP-Referer"] = "https://noche.live"
  req["X-Title"] = "Noche Live marks"
  req.body = JSON.generate(payload)
  res = http.request(req)
  body = res.body.to_s
  raise OpenRouterError, "#{res.code}: #{body}" unless res.is_a?(Net::HTTPSuccess)

  JSON.parse(body)
end

def generate_mark(prompt, dest)
  result = request(
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: "1:1",
    output_format: "jpeg"
  )
  first = Array(result["data"]).first
  abort "No image: #{result.inspect[0, 300]}" unless first

  if first["b64_json"]
    raw = first["b64_json"]
    raw = raw.split(",", 2).last if raw.start_with?("data:")
    FileUtils.mkdir_p(File.dirname(dest))
    File.binwrite(dest, Base64.decode64(raw))
    return
  end

  url = first["url"] || first.dig("image_url", "url")
  abort "No url: #{first.inspect[0, 300]}" unless url
  FileUtils.mkdir_p(File.dirname(dest))
  File.binwrite(dest, Net::HTTP.get(URI(url)))
end

kinds = %w[emblems icons avatars]
force = false
OptionParser.new do |opts|
  opts.on("--only KIND") { |value| kinds = value.split(",").map(&:strip) }
  opts.on("--force") { force = true }
end.parse!

spec = YAML.safe_load_file(SPEC_PATH)
style = spec.fetch("style").to_s.strip
puts "image model=#{IMAGE_MODEL}"

kinds.each do |kind|
  items = spec.fetch(kind)
  items.each do |key, shot|
    dest = File.join(OUT_ROOT, kind, "#{key}.jpg")
    if File.exist?(dest) && !force
      puts "skip #{dest.delete_prefix("#{ROOT}/")}"
      next
    end
    prompt = "#{style}\n\n#{shot}"
    puts "#{kind}/#{key} …"
    begin
      generate_mark(prompt, dest)
      puts "  wrote #{dest.delete_prefix("#{ROOT}/")}"
    rescue OpenRouterError => error
      warn "  skip #{kind}/#{key}: #{error.message[0, 220]}"
    end
  end
end
