#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate temple UI textures (hub marble hall background).
# Requires OPENROUTER_API_KEY.
#
#   ruby script/generate_temple_ui.rb
#   ruby script/generate_temple_ui.rb --force

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
OUT_DIR = File.join(ROOT, "public/media/temple")

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
  req["HTTP-Referer"] = "https://noche.live"
  req["X-Title"] = "Noche Live temple UI"
  req.body = JSON.generate(payload)

  res = http.request(req)
  body = res.body.to_s
  abort "OpenRouter #{res.code}: #{body}" unless res.is_a?(Net::HTTPSuccess)

  body.empty? ? {} : JSON.parse(body)
end

def generate_image(prompt, dest, aspect_ratio:)
  ext = File.extname(dest).delete(".").downcase
  format = ext == "jpg" || ext.empty? ? "jpeg" : ext
  result = request("#{API}/images", {
    model: IMAGE_MODEL,
    prompt: prompt,
    aspect_ratio: aspect_ratio,
    output_format: format
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

force = false
OptionParser.new do |opts|
  opts.on("--force") { force = true }
end.parse!

assets = {
  "marble-hall.jpg" => {
    aspect_ratio: "9:16",
    prompt: <<~PROMPT
      Vertical 9:16 empty environment plate matching a Salt Lake City celestial-room marble
      hall, for a mobile-game hub background. Strong one-point perspective down a deep
      center aisle. Two rows of tall fluted ivory marble columns with ornate warm gold-leaf
      Corinthian capitals, left and right, receding far into depth. Tall narrow arched
      windows and arched openings in the far wall with soft daylight pouring through.
      Subtle eight-pointed star motifs etched in the marble between the arches. Circular
      oculus in a high coffered ceiling with a warm cream god-ray onto the polished
      reflective marble floor. Empty center aisle — no furniture, no people, no rope,
      no UI, no cards, no HUD — so a game interface can sit in the middle. Painterly
      classical, cream ivory stone, sacred grandeur, not photoreal, not dark. No text,
      no logos, no watermarks, no letters, no crucifix, no Christus statue, no recommend
      desk, no ordinance-room veil, no pews.
    PROMPT
  },
  "marble-hall-victory.jpg" => {
    aspect_ratio: "9:16",
    prompt: <<~PROMPT
      Vertical 9:16 empty environment plate of a bright celestial white-marble temple
      hall for a victory screen. Strong one-point perspective. Tall fluted ivory marble
      columns with ornate gold-leaf Corinthian capitals. At the base of the columns,
      white marble planters with lush green leaves and gold-yellow flowers. Polished
      reflective white marble floor. Circular oculus above with strong warm cream
      god-rays. In the far distance, a glowing arched portal of warm gold-white light,
      empty doorway, no figure. Empty center aisle — no people, no furniture, no UI,
      no cards, no HUD, no buttons, no text, no letters, no logos. Painterly classical,
      ivory stone, sacred grandeur, very bright whites and golds. Not dark.
    PROMPT
  },
  "reward-chest.png" => {
    aspect_ratio: "1:1",
    prompt: <<~PROMPT
      Isolated premium AAA mobile-game UI prop, 3D product render, not a photograph,
      not a flat SVG icon, not a cartoon.
      Subject: one CLOSED wooden treasure chest, lid fully shut, no opening, no coins
      spilling, no inner glow, no sparkles, no fire, no hanging padlock ring.
      Camera: eye-level, slight 3/4 angle facing toward the right, as if the chest sits
      on a table in front of the viewer. NOT top-down, NOT a high angle, NOT isometric.
      The front face is clearly visible plus a sliver of the right side. Horizon at
      mid-chest. Lid is a low rounded dome.
      Materials: dark warm walnut wood planks with visible grain; thick polished brass
      and gold metal bands wrapping the body and the lid; round brass rivets; a
      prominent circular brass latch plate in the center of the front; metal has
      specular highlights.
      Lighting: soft studio key from the upper left, small soft contact shadow directly
      under the chest with translucent edges.
      Background: fully transparent alpha, clean knockout around the entire silhouette;
      no gray or white matte, no floor plane, no wall, no pedestal, no marble, no room,
      no gradient, no vignette, no scenery.
      Do not add text, letters, numbers, logos, UI, people, weapons, or a second object.
    PROMPT
  },
  "ceremony-chest.png" => {
    aspect_ratio: "1:1",
    prompt: <<~PROMPT
      Isolated game UI ornament: an open wooden treasure chest with gold-leaf trim, lid
      open toward camera, warm golden light and sparkles bursting from inside, sitting on
      a small circular ivory marble pedestal with a thin gold rim. Centered, large in
      frame, fully transparent background. Painterly cream and gold, no text, no letters,
      no logos, no people, no architecture besides the tiny pedestal.
    PROMPT
  },
  "ceremony-star.png" => {
    aspect_ratio: "1:1",
    prompt: <<~PROMPT
      Isolated game UI ornament: a single 3D faceted five-pointed golden star with a soft
      gold glow. Polished gold leaf, cream highlights. Centered, large in frame, fully
      transparent background. No text, no letters, no logos.
    PROMPT
  },
  "ceremony-lockup-mark.png" => {
    aspect_ratio: "1:1",
    prompt: <<~PROMPT
      Isolated game UI ornament: a tiny golden bee emblem, gold-leaf metal with cream
      highlights and a soft gold glow. Centered, large in frame, fully transparent
      background. No text, no letters, no logos, no people.
    PROMPT
  },
  "ceremony-laurel.png" => {
    aspect_ratio: "1:1",
    prompt: <<~PROMPT
      Isolated game UI ornament: a pair of golden laurel branches forming a U-shaped
      wreath, open at the top, gold-leaf metal with cream highlights and a soft gold
      glow. Centered, large in frame, fully transparent background. No chest, no text,
      no letters, no logos, no people.
    PROMPT
  }
}

puts "image model=#{IMAGE_MODEL}"
assets.each do |filename, config|
  dest = File.join(OUT_DIR, filename)
  if File.exist?(dest) && !force
    puts "skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end

  puts "#{filename} …"
  generate_image(config.fetch(:prompt), dest, aspect_ratio: config.fetch(:aspect_ratio))
  puts "  wrote #{dest.delete_prefix("#{ROOT}/")}"
end
