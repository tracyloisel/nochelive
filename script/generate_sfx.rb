#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate Noche Live cues via OpenRouter (Lyria 3 Clip).
# Requires OPENROUTER_API_KEY. Writes public/sfx/<name>.mp3.
#
#   ruby script/generate_sfx.rb
#   ruby script/generate_sfx.rb --only tick,timer_tension --force
#   ruby script/generate_sfx.rb --only study_refuge --remaster-existing

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
OUT_ROOT = File.expand_path(ENV.fetch("SFX_OUT_ROOT", File.join(ROOT, "public", "sfx")), ROOT)
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
  req["HTTP-Referer"] = "https://nochelive.com"
  req["X-Title"] = "Noche Live sfx"
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
        if json["error"]
          message = json.dig("error", "message") || json["error"].to_s
          raise OpenRouterError, message
        end
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
  req["HTTP-Referer"] = "https://nochelive.com"
  req["X-Title"] = "Noche Live sfx"
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
    audio: { format: "mp3", voice: "alloy" },
    stream: true
  }

  chunks = request_stream(payload)
  if chunks.any?
    joined = chunks.join
    return decode_audio(joined) if chunks.size == 1 || joined.match?(%r{\A[A-Za-z0-9+/=\s]+\z})

    return chunks.pack("C*") if chunks.all? { |chunk| chunk.bytesize == 1 }
    return Base64.decode64(joined)
  end

  raise OpenRouterError, "Streaming response completed without audio data"
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

def audio_duration(path)
  out, status = Open3.capture2e(
    "ffprobe", "-v", "error", "-show_entries", "format=duration",
    "-of", "default=noprint_wrappers=1:nokey=1", path
  )
  duration = out.to_f
  duration if status.success? && duration.positive?
rescue Errno::ENOENT
  nil
end

def trim_mp3(src, dest, max_seconds:, loopable:, master: nil)
  return FileUtils.cp(src, dest) unless ffmpeg?

  if loopable && (duration = audio_duration(src)) && duration > 6
    crossfade = [ 1.5, duration * 0.08 ].min
    middle_end = duration - crossfade
    extra_inputs = []
    source = if master == "focus_music"
      [
        "[0:a]highpass=f=120,lowpass=f=9000,acompressor=threshold=0.08:ratio=4:attack=180:release=2200:makeup=1,asplit=3[source_middle][source_tail][source_head]"
      ]
    elsif master == "still_refuge"
      extra_inputs = [
        "-f", "lavfi", "-i",
        "anoisesrc=color=pink:sample_rate=48000:amplitude=0.04:duration=#{format("%.3f", duration)}"
      ]
      [
        "[0:a]pan=mono|c0=0.5*c0+0.5*c1,highpass=f=240,lowpass=f=1600,volume=0.01[ghost]",
        "[1:a]highpass=f=180,lowpass=f=1600,volume=0.60[air]",
        "[ghost][air]amix=inputs=2:normalize=0,acompressor=threshold=0.025:ratio=10:attack=250:release=3000:makeup=1,atrim=end=#{format("%.3f", duration)},asetpts=PTS-STARTPTS,pan=stereo|c0=c0|c1=c0,asplit=3[source_middle][source_tail][source_head]"
      ]
    else
      [ "[0:a]asplit=3[source_middle][source_tail][source_head]" ]
    end
    finish = if master == "focus_music"
      "[middle][seam]concat=n=2:v=0:a=1,loudnorm=I=-19:LRA=3:TP=-3,aeval=exprs='val(0)+0.0012*sin(2*PI*174*t)|val(1)+0.0012*sin(2*PI*184*t)'[out]"
    elsif master == "still_refuge"
      "[middle][seam]concat=n=2:v=0:a=1,loudnorm=I=-20:LRA=1:TP=-6,aeval=exprs='val(0)+0.0008*sin(2*PI*174*t)|val(1)+0.0008*sin(2*PI*184*t)'[out]"
    else
      "[middle][seam]concat=n=2:v=0:a=1,loudnorm=I=-18:LRA=4:TP=-2[out]"
    end
    filter = source + [
      "[source_middle]atrim=start=#{format("%.3f", crossfade)}:end=#{format("%.3f", middle_end)},asetpts=PTS-STARTPTS[middle]",
      "[source_tail]atrim=start=#{format("%.3f", middle_end)}:end=#{format("%.3f", duration)},asetpts=PTS-STARTPTS[tail]",
      "[source_head]atrim=start=0:end=#{format("%.3f", crossfade)},asetpts=PTS-STARTPTS[head]",
      "[tail][head]acrossfade=d=#{format("%.3f", crossfade)}:c1=tri:c2=tri[seam]",
      finish
    ]
    filter = filter.join(";")
    cmd = [
      "ffmpeg", "-y", "-i", src,
      *extra_inputs,
      "-filter_complex", filter, "-map", "[out]",
      "-c:a", "libmp3lame", "-q:a", "4",
      dest
    ]
  else
    fade = format("%.3f", fade_out_seconds(max_seconds))
    limit = format("%.3f", max_seconds)
    filter = "silenceremove=start_periods=1:start_threshold=-34dB:start_silence=0.02:stop_periods=1:stop_threshold=-34dB:stop_duration=0.12,atrim=end=#{limit},asetpts=PTS-STARTPTS,areverse,afade=t=in:d=#{fade},areverse"
    cmd = [
      "ffmpeg", "-y", "-i", src,
      "-af", filter,
      "-c:a", "libmp3lame", "-q:a", "4",
      dest
    ]
  end

  out, status = Open3.capture2e(*cmd)
  if !status.success? || !File.exist?(dest) || File.size(dest) < 400
    FileUtils.cp(src, dest)
  end
end

style = YAML.safe_load_file(SPEC_PATH).fetch("style").to_s.strip
cues = YAML.safe_load_file(SPEC_PATH).fetch("cues")
only = nil
force = false
remaster_existing = false
OptionParser.new do |opts|
  opts.on("--only NAMES") { |value| only = value.split(",").map(&:strip) }
  opts.on("--force") { force = true }
  opts.on("--remaster-existing") { remaster_existing = true }
end.parse!

names = only || cues.keys
unknown = names - cues.keys
abort "Unknown cues: #{unknown.join(", ")}" if unknown.any?

puts "audio model=#{AUDIO_MODEL}"
puts "ffmpeg=#{ffmpeg? ? "yes" : "no"}"

names.each do |name|
  spec = cues.fetch(name)
  dest = File.join(OUT_ROOT, "#{name}.mp3")
  if remaster_existing
    abort "Missing existing cue: #{dest}" unless File.exist?(dest)

    raw = File.join(OUT_ROOT, ".#{name}.remaster.raw.mp3")
    FileUtils.cp(dest, raw)
    trim_mp3(
      raw,
      dest,
      max_seconds: spec.fetch("max_seconds").to_f,
      loopable: spec["kind"] == "loop",
      master: spec["master"]
    )
    FileUtils.rm_f(raw)
    puts "remastered #{dest.delete_prefix("#{ROOT}/")} (#{File.size(dest)} bytes)"
    next
  end

  if File.exist?(dest) && !force
    puts "skip #{dest.delete_prefix("#{ROOT}/")}"
    next
  end

  prompt = "#{style}\n\n#{spec.fetch("prompt")}"
  puts "#{name} …"
  begin
    bytes = generate_bytes(prompt)
    raw = File.join(OUT_ROOT, ".#{name}.raw")
    write_mp3(raw, bytes)
    trim_mp3(
      raw,
      dest,
      max_seconds: spec.fetch("max_seconds").to_f,
      loopable: spec["kind"] == "loop",
      master: spec["master"]
    )
    FileUtils.rm_f(raw)
    puts "  wrote #{dest.delete_prefix("#{ROOT}/")} (#{File.size(dest)} bytes)"
  rescue OpenRouterError => error
    warn "  skip #{name}: #{error.message[0, 240]}"
  end
end
