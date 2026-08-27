#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate mapa screen audio cues via OpenRouter (Lyria 3 Clip).
# Requires OPENROUTER_API_KEY. Writes public/sfx/mapa_*.mp3.
#
#   ruby script/generate_mapa_sfx.rb
#   ruby script/generate_mapa_sfx.rb --only mapa_enter,mapa_unlock --force
#   ruby script/generate_mapa_sfx.rb --force

require "base64"
require "fileutils"
require "json"
require "net/http"
require "open3"
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

SPEC_PATH = File.join(ROOT, "config/media/sfx.yml")
OUT_ROOT = File.join(ROOT, "public", "sfx")
API = "https://openrouter.ai/api/v1"
AUDIO_MODEL = ENV.fetch("OPENROUTER_AUDIO_MODEL", "google/lyria-3-clip-preview")

class OpenRouterError < StandardError; end

def api_key
  key = ENV["OPENROUTER_API_KEY"].to_s.strip
  abort "OPENROUTER_API_KEY is missing." if key.empty?

  key
end

def ffmpeg?
  _out, status = Open3.capture2e("ffmpeg", "-version")
  status.success?
rescue Errno::ENOENT
  false
end

def request_stream(payload)
  uri = URI("#{API}/chat/completions")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 180
  http.open_timeout = 20
  req = Net::HTTP::Post.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"] = "application/json"
  req["HTTP-Referer"] = "https://noche.live"
  req["X-Title"] = "Noche Live mapa SFX"
  req["Accept"] = "text/event-stream"
  req.body = JSON.generate(payload)

  chunks = []
  http.request(req) do |res|
    body_head = +""
    unless res.is_a?(Net::HTTPSuccess)
      res.read_body { |part| body_head << part }
      raise OpenRouterError, "#{res.code}: #{body_head[0, 400]}"
    end

    buf = +""
    res.read_body do |part|
      buf << part
      while (idx = buf.index("\n"))
        line = buf.slice!(0, idx + 1).strip
        next if line.empty? || line.start_with?(":")
        next unless line.start_with?("data:")

        data = line.delete_prefix("data:").strip
        break if data == "[DONE]"

        json = JSON.parse(data)
        audio = json.dig("choices", 0, "delta", "audio") || json.dig("choices", 0, "message", "audio")
        piece = audio.is_a?(Hash) ? (audio["data"] || audio["b64_json"]) : audio
        chunks << piece if piece.is_a?(String) && !piece.empty?
      end
    end
  end

  chunks
end

def request_json(payload)
  uri = URI("#{API}/chat/completions")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 180
  http.open_timeout = 20
  req = Net::HTTP::Post.new(uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"] = "application/json"
  req["HTTP-Referer"] = "https://noche.live"
  req["X-Title"] = "Noche Live mapa SFX"
  req.body = JSON.generate(payload.merge(stream: false))
  res = http.request(req)
  body = res.body.to_s
  raise OpenRouterError, "#{res.code}: #{body[0, 400]}" unless res.is_a?(Net::HTTPSuccess)

  JSON.parse(body)
end

def extract_b64(result)
  message = result.dig("choices", 0, "message") || {}
  audio = message["audio"]
  if audio.is_a?(Hash)
    return audio["data"] || audio["b64_json"]
  end

  Array(message["content"]).each do |part|
    next unless part.is_a?(Hash)
    inline = part["inline_data"] || part["input_audio"] || part["audio"]
    next unless inline.is_a?(Hash)

    data = inline["data"] || inline["b64_json"]
    return data if data
  end

  nil
end

def decode_audio(b64)
  raw = b64.to_s
  raw = raw.split(",", 2).last if raw.start_with?("data:")
  Base64.decode64(raw)
end

def generate_bytes(prompt)
  payload = {
    model: AUDIO_MODEL,
    messages: [ { role: "user", content: prompt } ],
    modalities: [ "text", "audio" ],
    stream: true
  }

  chunks = request_stream(payload)
  if chunks.any?
    joined = chunks.join
    return decode_audio(joined) if chunks.size == 1 || joined.match?(/\A[A-Za-z0-9+\/=\s]+\z/)

    return chunks.pack("C*") if chunks.all? { |chunk| chunk.bytesize == 1 }
    return Base64.decode64(joined)
  end

  fallback = payload.reject { |key, _| key == :stream }.merge(stream: false)
  result = request_json(fallback)
  b64 = extract_b64(result)
  raise OpenRouterError, "No audio: #{result.inspect[0, 300]}" if b64.nil? || b64.empty?

  decode_audio(b64)
end

def write_mp3(dest, bytes)
  FileUtils.mkdir_p(File.dirname(dest))
  File.binwrite(dest, bytes)
end

def fade_out_seconds(max_seconds)
  max = max_seconds.to_f
  return 0.03 if max <= 0.25
  return 0.08 if max <= 0.7
  [ max * 0.14, 0.24 ].min
end

def trim_mp3(src, dest, max_seconds:, loopable:)
  return FileUtils.cp(src, dest) unless ffmpeg?

  filter = if loopable
    "afade=t=in:st=0:d=0.04,afade=t=out:st=#{[ max_seconds - 0.08, 0 ].max}:d=0.08"
  else
    fade = format("%.3f", fade_out_seconds(max_seconds))
    "silenceremove=start_periods=1:start_threshold=-34dB:start_silence=0.02:stop_periods=1:stop_threshold=-34dB:stop_duration=0.12,areverse,afade=t=in:d=#{fade},areverse"
  end

  cmd = [
    "ffmpeg", "-y", "-i", src,
    "-t", format("%.2f", max_seconds),
    "-af", filter,
    "-c:a", "libmp3lame", "-q:a", "4",
    dest
  ]
  out, status = Open3.capture2e(*cmd)
  if !status.success? || !File.exist?(dest) || File.size(dest) < 400
    FileUtils.cp(src, dest)
  end
end

mapa_style = "Warm, gentle, golden audio texture. No vocals, no TTS, no dramatic orchestra. Subtle, mobile-game UI feel. Gold-warm, celestial, hopeful."

mapa_cues = {
  "mapa_enter" => {
    prompt: "#{mapa_style}\n\nA soft celestial breath entering a new screen — golden warmth, gentle swell, peaceful. 2 seconds max.",
    max_seconds: 2.0,
    loopable: false
  },
  "mapa_selection" => {
    prompt: "#{mapa_style}\n\nA soft gold chime selecting a game node — bright but gentle, single tone. 0.4 seconds max.",
    max_seconds: 0.4,
    loopable: false
  },
  "mapa_unlock" => {
    prompt: "#{mapa_style}\n\nA satisfying unlock sound — light click followed by ascending golden shimmer. 0.8 seconds max.",
    max_seconds: 0.8,
    loopable: false
  },
  "mapa_chest" => {
    prompt: "#{mapa_style}\n\nA treasure chest opening — mechanical click, then warm golden shimmer with sparkle. 1.5 seconds max.",
    max_seconds: 1.5,
    loopable: false
  },
  "mapa_tier_up" => {
    prompt: "#{mapa_style}\n\nA tier level-up sound — ascending melodic progression, golden and triumphant but gentle. 1.2 seconds max.",
    max_seconds: 1.2,
    loopable: false
  },
  "mapa_royal" => {
    prompt: "#{mapa_style}\n\nA royal fanfare for completing all 50 packs — full golden ascent, majestic but not overwhelming, warm ending. 3 seconds max.",
    max_seconds: 3.0,
    loopable: false
  }
}

only = nil
force = false
OptionParser.new do |opts|
  opts.on("--only NAMES") { |value| only = value.split(",").map(&:strip) }
  opts.on("--force") { force = true }
end.parse!

names = only || mapa_cues.keys
unknown = names - mapa_cues.keys
abort "Unknown cues: #{unknown.join(", ")}" if unknown.any?

puts "audio model=#{AUDIO_MODEL}"
puts "ffmpeg=#{ffmpeg? ? "yes" : "no"}"

names.each do |name|
  spec = mapa_cues.fetch(name)
  dest = File.join(OUT_ROOT, "#{name}.mp3")
  if File.exist?(dest) && !force
    puts "skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end

  puts "#{name} …"
  begin
    bytes = generate_bytes(spec[:prompt])
    raw = File.join(OUT_ROOT, ".#{name}.raw")
    write_mp3(raw, bytes)
    trim_mp3(raw, dest, max_seconds: spec[:max_seconds], loopable: spec[:loopable])
    FileUtils.rm_f(raw)
    puts "  wrote #{dest.delete_prefix("#{ROOT}/")} (#{File.size(dest)} bytes)"
  rescue OpenRouterError => error
    warn "  skip #{name}: #{error.message[0, 240]}"
  end
end