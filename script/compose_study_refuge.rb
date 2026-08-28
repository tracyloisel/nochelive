#!/usr/bin/env ruby
# frozen_string_literal: true

# Compose Noche Live's scripture-reading bed locally with FFmpeg.
#
# This is deliberately a piece of ambient music rather than a generated SFX:
# four overlapping add-nine / suspended harmonies, very slow note envelopes,
# no pulse, no percussion and no low-frequency attacks. The final 1.5 seconds
# crossfade back into the opening harmony so stage_controller can loop it.
#
#   ruby script/compose_study_refuge.rb

require "fileutils"
require "open3"
require "tempfile"

ROOT = File.expand_path("..", __dir__)
DESTINATION = File.join(ROOT, "public", "sfx", "study_refuge.mp3")
SAMPLE_RATE = 48_000
SOURCE_SECONDS = 31.5
LOOP_SECONDS = 30.0
CROSSFADE_SECONDS = 1.5

# Voicings stay above the sub-bass range and leave the speech band uncluttered.
# They form an original, unresolved progression that returns to its first chord.
CHORDS = [
  { name: "Dmaj9/A", notes: [ 220.00, 277.18, 329.63, 369.99, 440.00 ], start: 0.0, duration: 7.0, fade_in: 0.0, fade_out: 4.0 },
  { name: "Bm11/F#", notes: [ 185.00, 220.00, 246.94, 277.18, 329.63 ], start: 3.0, duration: 11.0, fade_in: 4.0, fade_out: 4.0 },
  { name: "Gmaj9/D", notes: [ 196.00, 246.94, 293.66, 369.99, 440.00 ], start: 10.0, duration: 11.0, fade_in: 4.0, fade_out: 4.0 },
  { name: "Asus4(add9)/E", notes: [ 220.00, 246.94, 293.66, 329.63, 440.00 ], start: 17.0, duration: 11.0, fade_in: 4.0, fade_out: 4.0 },
  { name: "Dmaj9/A return", notes: [ 220.00, 277.18, 329.63, 369.99, 440.00 ], start: 24.0, duration: 7.5, fade_in: 4.0, fade_out: 0.0 }
].freeze

NOTE_WEIGHTS = [ 0.86, 0.68, 0.52, 0.39, 0.28 ].freeze

def fmt(value)
  format("%.5f", value)
end

def note_layer(frequency, weight, index)
  # Three almost-unison oscillators make a wide, breathing pad without a
  # rhythmic LFO. A tiny second partial adds warmth while remaining sine-soft.
  phase = index * 0.47
  [
    "#{fmt(weight)}*sin(2*PI*#{fmt(frequency * 0.9992)}*t+#{fmt(phase)})",
    "#{fmt(weight * 0.72)}*sin(2*PI*#{fmt(frequency)}*t+#{fmt(phase + 0.83)})",
    "#{fmt(weight * 0.56)}*sin(2*PI*#{fmt(frequency * 1.0009)}*t+#{fmt(phase + 1.61)})",
    "#{fmt(weight * 0.045)}*sin(2*PI*#{fmt(frequency * 2.0)}*t+#{fmt(phase + 0.29)})"
  ]
end

def chord_expression(notes)
  layers = notes.each_with_index.flat_map do |frequency, index|
    note_layer(frequency, NOTE_WEIGHTS.fetch(index), index)
  end
  "(#{layers.join("+")})/5.8"
end

def chord_filter(chord, index)
  label = "chord#{index}"
  filters = [
    "aevalsrc=exprs='#{chord_expression(chord.fetch(:notes))}':s=#{SAMPLE_RATE}:d=#{fmt(chord.fetch(:duration))}",
    "pan=stereo|c0=c0|c1=c0",
    "highpass=f=150",
    "lowpass=f=6200:p=2"
  ]

  fade_in = chord.fetch(:fade_in)
  filters << "afade=t=in:st=0:d=#{fmt(fade_in)}:curve=qsin" if fade_in.positive?

  fade_out = chord.fetch(:fade_out)
  if fade_out.positive?
    fade_start = chord.fetch(:duration) - fade_out
    filters << "afade=t=out:st=#{fmt(fade_start)}:d=#{fmt(fade_out)}:curve=qsin"
  end

  start_ms = (chord.fetch(:start) * 1000).round
  filters << "adelay=#{start_ms}:all=1" if start_ms.positive?
  "#{filters.join(",")}[#{label}]"
end

def compose_filter
  graph = CHORDS.each_with_index.map { |chord, index| chord_filter(chord, index) }
  chord_labels = CHORDS.each_index.map { |index| "[chord#{index}]" }.join

  graph << "#{chord_labels}amix=inputs=#{CHORDS.length}:normalize=0:dropout_transition=0," \
           "acompressor=threshold=0.10:ratio=2.2:attack=350:release=2400:makeup=1," \
           "chorus=0.55:0.72:47|61:0.11|0.09:0.08|0.07:0.25|0.19," \
           "aecho=0.72:0.80:310|740|1310:0.10|0.07|0.035," \
           "highpass=f=145,lowpass=f=7800:p=2," \
           "atrim=end=#{fmt(SOURCE_SECONDS)},asetpts=PTS-STARTPTS[pad]"

  # A nearly subliminal band of air keeps the synthesis from feeling sterile;
  # it is far quieter and narrower than a noise bed.
  graph << "anoisesrc=color=pink:sample_rate=#{SAMPLE_RATE}:amplitude=0.003:duration=#{fmt(SOURCE_SECONDS)}," \
           "highpass=f=900,lowpass=f=5200,pan=stereo|c0=c0|c1=c0[air]"
  graph << "[pad][air]amix=inputs=2:normalize=0:dropout_transition=0," \
           "asplit=3[source_middle][source_tail][source_head]"

  middle_end = SOURCE_SECONDS - CROSSFADE_SECONDS
  graph << "[source_middle]atrim=start=#{fmt(CROSSFADE_SECONDS)}:end=#{fmt(middle_end)}," \
           "asetpts=PTS-STARTPTS[middle]"
  graph << "[source_tail]atrim=start=#{fmt(middle_end)}:end=#{fmt(SOURCE_SECONDS)}," \
           "asetpts=PTS-STARTPTS[tail]"
  graph << "[source_head]atrim=start=0:end=#{fmt(CROSSFADE_SECONDS)}," \
           "asetpts=PTS-STARTPTS[head]"
  graph << "[tail][head]acrossfade=d=#{fmt(CROSSFADE_SECONDS)}:c1=qsin:c2=qsin[seam]"

  # The 174/184 Hz carriers create a subtle 10 Hz binaural difference on
  # headphones. They sit below the music and are never amplitude-pulsed.
  graph << "[middle][seam]concat=n=2:v=0:a=1," \
           "atrim=end=#{fmt(LOOP_SECONDS)}," \
           "loudnorm=I=-19:LRA=3:TP=-3," \
           "aeval=exprs='val(0)+0.0011*sin(2*PI*174*t)|val(1)+0.0011*sin(2*PI*184*t)'[out]"

  graph.join(";")
end

def ffmpeg_available?
  _output, status = Open3.capture2e("ffmpeg", "-version")
  status.success?
rescue Errno::ENOENT
  false
end

abort "ffmpeg is required to compose study_refuge.mp3" unless ffmpeg_available?

FileUtils.mkdir_p(File.dirname(DESTINATION))

Tempfile.create([ "study_refuge", ".mp3" ], File.dirname(DESTINATION)) do |temp|
  temp.close
  command = [
    "ffmpeg", "-hide_banner", "-y",
    "-filter_complex", compose_filter,
    "-map", "[out]",
    "-t", fmt(LOOP_SECONDS),
    "-c:a", "libmp3lame", "-q:a", "3",
    temp.path
  ]

  output, status = Open3.capture2e(*command)
  unless status.success? && File.exist?(temp.path) && File.size(temp.path) > 10_000
    warn output
    abort "Composition failed; the existing cue was left untouched."
  end

  FileUtils.mv(temp.path, DESTINATION)
end

puts "Composed #{DESTINATION}"
puts "Harmony: #{CHORDS.map { |chord| chord.fetch(:name) }.join(" -> ")}"
