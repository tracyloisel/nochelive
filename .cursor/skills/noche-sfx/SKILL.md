---
name: noche-sfx
description: >-
  Designs Noche Live's named sound cues, OpenRouter generation, pulses, and
  Web Audio playback (one-shots, timer bed, ticks). Use when changing SFX,
  MP3s, sfx.yml, Sfx, stage_controller, countdown audio, pulses, mute, or
  presenter/player live sounds.
---

# Noche Live SFX

Read this before adding or changing a sound.

## Soul

Family quiz in a chapel cultural hall, not a stadium and not a horror film.

- Instrumental only: no vocals, lyrics, speech, choir, or church organ.
- Gold-warm, dry, close-mic'd for a phone speaker.
- Kind, not punishing. Kids are in the room.
- One **named cue** in game logic. Never a file path in services, YAML rounds, or views.

## Files

| Path | Role |
|---|---|
| `config/media/sfx.yml` | World lock + per-cue prompt, `kind`, `max_seconds` |
| `public/sfx/<name>.mp3` | The recording. MP3 only. |
| `app/models/sfx.rb` | `CUES`, `path_for`, `for_pulse` |
| `app/javascript/controllers/stage_controller.js` | Play, bed, ticks, mute |
| `script/generate_sfx.rb` | OpenRouter Lyria, offline |

```bash
export OPENROUTER_API_KEY=sk-or-...
ruby script/generate_sfx.rb --only tick,buzzer_hit --force
```

Model: `OPENROUTER_AUDIO_MODEL` (default `google/lyria-3-clip-preview`). Generate **before** the night. Never call OpenRouter from a request or Stimulus.

## Layers

Already wired on `<body data-controller="stage press motion">`. First pointerdown unlocks Web Audio.

| Layer | How | Gain |
|---|---|---|
| One-shot | `stage.play(name)` or pulse `data-sfx` | `0.85` |
| Bed | `data-stage-bed-value` on `#night_play`, `#night_watch`, `#night_presenter`, `#street_quiz` | `0.35`, `loop` |
| Tick | `data-stage-timer-end-value` on those same nodes | `tick` `0.42`, `tick_low` `0.58` (last 5s) |

`countdown_controller.js` is **visual only**. The presenter-claim timer must not tick. Bed and ticks follow round `timed?` + `ends_at` on the three stage roots **and** `#street_quiz`, not the `.play-timer` DOM (the TV has no bar). Street quiz has **one** trigger: `data-stage-*` on `#street_quiz`. Do not also `quiz_controller#cue()` on the street (keep cue for the Friday play reel). There is no Cable pulse on the street.

Mute is the **Sonido** button (`noche_sfx_muted`). `prefers-reduced-motion` does not silence audio. It **does** hide flash veils (`is-fx-*`).

## When it plays

Presenter actions travel as **pulses** so phones, TV, and console hear them:

| Pulse `kind` | Cue |
|---|---|
| `open` | `round_open` |
| `advance` | `question_change` |
| `lock` | `round_lock` |
| `freeze` | `dramatic_fire` |
| `reveal` | `reveal` |
| `buzz` / `found` / `shout` | `buzzer_hit` |
| `join` / `pose` | `chest` |
| `score` | `correct_gold` |

`stage_sfx` is leftover atmosphere (intro, rank-up, finale), **not** open / lock / reveal — pulses already fire those. Replay the same cue on the next round with `data-stage-sfx-token-value` (`round.id` + `phase`). Do not compare cue name alone.

Open / lock / reveal / forward / complete belong in `app/services/rounds/`, with `broadcast_state(pulse: …)`.

## Adding a cue

1. Name it in `Sfx::CUES` and `config/media/sfx.yml`.
2. Generate the MP3. `test/models/sfx_test.rb` requires `/sfx/<name>.mp3`.
3. Wire **one** trigger: a pulse kind **or** `stage_sfx` **or** `stage.play` from a Stimulus controller — not two.
4. Preload happens from `window.NocheSfx` in the layout catalog.

```text
# BAD — path in the round, second player, live API, WAV leftover
definition.sfx["file"] = "/sfx/hit.wav"
fetch("https://openrouter.ai/...")

# GOOD
Sfx::CUES << "harp_gliss"
# sfx.yml prompt + ruby script/generate_sfx.rb --only harp_gliss
pulse: { kind: "open" }  # maps in Sfx::PULSE
```

## Do not

- Add WAV, AIFF, or a Python oscillator “placeholder”.
- Use TTS (`/audio/speech`) for hits, ticks, or stingers.
- Invent a second AudioContext or a Howler/Tone stack.
- Start the tension bed from `.play-timer` only (watch/presenter go silent).
- Restart the bed on every Turbo presence replace (same `ends_at` → keep the loop).
- Double-play a stinger from both the pulse and `data-stage-sfx-value`.

## Checklist

- [ ] Cue has a name in `Sfx::CUES` and an MP3
- [ ] Prompt lives in `sfx.yml` (chapel, no voice, then silence for one-shots)
- [ ] One trigger path; token changes when the same name must replay
- [ ] Timed rounds set bed + timer on play, watch, **and** presenter
- [ ] Mute still cuts bed and ticks
- [ ] Tests cover the mapping (`Sfx.for_pulse`, `stage_sfx` / `stage_bed`, pulse partial)
