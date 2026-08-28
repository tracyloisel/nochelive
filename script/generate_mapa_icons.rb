#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate mapa screen icons via OpenRouter Flux.
# Requires OPENROUTER_API_KEY. Writes public/media/ui/mapa-icons/*.png.
#
#   ruby script/generate_mapa_icons.rb
#   ruby script/generate_mapa_icons.rb --only mapa-crown,mapa-chest
#   ruby script/generate_mapa_icons.rb --force

require "base64"
require "fileutils"
require "json"
require "net/http"
require "optparse"
require "uri"

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

API = "https://openrouter.ai/api/v1"
IMAGE_MODEL = ENV.fetch("OPENROUTER_IMAGE_MODEL", "black-forest-labs/flux.2-flex")
OUT_DIR = File.join(ROOT, "public/media/ui/mapa-icons")
SIZE = 128

def api_key
  key = ENV["OPENROUTER_API_KEY"].to_s.strip
  abort "OPENROUTER_API_KEY is missing. Export it, then rerun." if key.empty?

  key
end

def request(url, payload, timeout: 900)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = timeout
  http.open_timeout = 20

  req = Net::HTTP::Post.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"] = "application/json"
  req["HTTP-Referer"] = "https://nochelive.com"
  req["X-Title"] = "Noche Live mapa icons"
  req.body = JSON.generate(payload)

  res = http.request(req)
  body = res.body.to_s
  abort "OpenRouter #{res.code}: #{body}" unless res.is_a?(Net::HTTPSuccess)

  body.empty? ? {} : JSON.parse(body)
end

def generate_image(prompt, dest)
  result = request("#{API}/images", {
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: "1:1",
    output_format: "png"
  })
  first = Array(result["data"]).first
  abort "No image data: #{result.inspect[0, 400]}" unless first

  b64 = first["b64_json"]
  abort "No b64_json: #{first.inspect[0, 400]}" unless b64

  raw = b64.split(",", 2).last if b64.start_with?("data:")
  FileUtils.mkdir_p(File.dirname(dest))
  File.binwrite(dest, Base64.decode64(raw))
end

icons = {
  "mapa-pack-box.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a small closed book or pack case in warm gold
      and ivory tones. Front-facing, slightly angled 3/4 view. Polished gold metal
      trim with a clasp in the center. Cream ivory surface with subtle texture.
      Soft studio lighting, contact shadow underneath. Fully transparent background.
      No text, no letters, no logos. AAA mobile-game art style, polished, not flat.
    PROMPT
  },
  "mapa-question.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a large question mark symbol in warm gold.
      Slightly 3D, faceted gold leaf finish with cream highlights. Centered, bold.
      Soft gold glow, contact shadow underneath. Fully transparent background.
      No text, no letters, no logos. Clean, readable at small size, AAA mobile game style.
    PROMPT
  },
  "mapa-crown.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a royal crown in warm polished gold.
      Three visible peaks with a rounded band. Gold leaf finish with cream highlights.
      Centered, bold. Soft gold glow, contact shadow underneath. Fully transparent
      background. No text, no letters, no logos. AAA mobile game style, premium.
    PROMPT
  },
  "mapa-chest.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a small closed treasure chest in warm walnut
      wood with gold metal bands. Front-facing 3/4 view. Prominent brass latch in
      center. Polished gold trim, cream highlights. Soft studio key light from upper
      left. Contact shadow underneath. Fully transparent background. No text, no
      letters, no logos. AAA mobile game style.
    PROMPT
  },
  "mapa-key.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a stylized key or scepter in warm gold,
      representing prophets. Ornate handle with a circular top, tapered shaft, and
      simple teeth. Gold leaf finish with cream highlights. Centered, bold. Soft
      gold glow, contact shadow underneath. Fully transparent background. No text,
      no letters, no logos. AAA mobile game style, polished.
    PROMPT
  },
  "mapa-tree.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a stylized tree in warm gold. Trunk with
      branching arms and a canopy of simple leaves. Gold leaf finish, cream
      highlights. Centered, bold. Soft gold glow, contact shadow underneath.
      Fully transparent background. No text, no letters, no logos. AAA mobile game
      style, clean and readable.
    PROMPT
  },
  "mapa-shield-cross.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a small shield with a centered cross, in
      warm polished gold. Shield shape is rounded at bottom, slightly curved top.
      Gold leaf finish with cream highlights. Centered, bold. Soft gold glow,
      contact shadow underneath. Fully transparent background. No text, no letters,
      no logos. AAA mobile game style, premium.
    PROMPT
  },
  "mapa-trophy.png" => {
    prompt: <<~PROMPT
      Isolated 128x128 game UI icon: a small trophy cup in warm gold. Classic cup
      shape with two handles, pedestal base, and gold rim. Gold leaf finish with
      cream highlights. Centered, bold. Soft gold glow, contact shadow underneath.
      Fully transparent background. No text, no letters, no logos. AAA mobile game
      style, polished.
    PROMPT
  }
}

force = false
only = nil
OptionParser.new do |opts|
  opts.on("--force") { force = true }
  opts.on("--only LIST") { |value| only = value.split(",").map(&:strip) }
end.parse!

filenames = only || icons.keys

puts "image model=#{IMAGE_MODEL}"
filenames.each do |filename|
  config = icons[filename]
  abort "Unknown icon: #{filename}" unless config

  dest = File.join(OUT_DIR, filename)
  if File.exist?(dest) && !force
    puts "skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end

  puts "#{filename} …"
  generate_image(config[:prompt], dest)
  puts "  wrote #{dest.delete_prefix("#{ROOT}/")}"
end
