# M2 — Moment voice review

Reviewed: 2026-08-24
Slice: original named SFX recordings + rank-up event + finale intensity 5
Tests: `bundle exec rails test` — 17 runs, 105 assertions, 0 failures
Gate: `.cursor/skills/noche-night/SKILL.md`. Sound hat below is evidence. Live audio gate: `.cursor/skills/noche-sfx/SKILL.md`.

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Rank-up and finale still one next action; pulses carry the voice |
| Equipo en sala | Hears the same named cues as the slam |
| Jugador en casa | Same cues, not a silent spectator leftover |
| Espectador | TV hears the bed and stingers |

Named cues now ship as OpenRouter MP3s (`public/sfx/*.mp3`), not WAV placeholders. This slice named the catalog.

---

## Evidence

Sound Designer

## Verdict

PASS

## Score impact

Sound: 4/5

## What works

- Cues are named (`buzzer_hit`, `correct_gold`, `level_up`, `royal_fanfare`). Paths live in `Sfx` / the sound controller only.
- Files are original named recordings (`Sfx` catalog). Current files are MP3 (Lyria), generated offline.
- Mute still works. Autoplay failure is silent. Reduced motion no longer kills sound.

## What feels weak

- The recordings are still synthesized performances, not a designed session mix.
- Wrong/correct could be more distinct in a noisy living room.

## Highest-value improvement

A louder, shorter buzzer hit and a warmer correct chord.

## Required before approval

- None.

---

## Evidence

Progression Designer

## Verdict

PASS

## Score impact

Progression: 5/5

## What works

- Crossing a rank is no longer a label change. The night stops. Crown. "Nueva dignidad." Fanfare.
- Spectator shouts the new rank. The player became something.

## What feels weak

- Only session ranks. No role yet.

## Highest-value improvement

One temporary role on rank-up (Rey / Profeta) for the next round.

## Required before approval

- None.

---

## Evidence

VFX / Motion Designer

## Verdict

PASS WITH NOTES

## Score impact

VFX: 4/5

## What works

- Rank-up and finale use intensity 5 classes (`level`, `finale`) instead of another generic gold flash only.
- Finale has a distinct podium + confetti marks. Reduced motion still flattens animation.

## What feels weak

- Confetti is still three gold shards, not a celebration system.

## Highest-value improvement

More finale particles, still CSS, still reduced-motion safe.

## Required before approval

- None.

---

## Evidence

Pacing Director

## Verdict

PASS

## Score impact

Pacing: 4/5

## What works

- The night now has a mid peak (rank-up) and an end peak (finale fanfare).
- Those peaks are not "question 15, +10."

## What feels weak

- A short 3-round playtest may never hear the finale.

## Highest-value improvement

None for this slice.

---

## Evidence

UX Accessibility Tester

## Verdict

PASS

## Score impact

Clarity: 4/5
Accessibility: 4/5

## What works

- Rank-up copy is short. One button: Seguir la noche.
- Sound is not required. Mute is obvious.
- Reduced motion still removes animation; sound remains available.

## What feels weak

- Two events can queue (chest + rank-up). Rank-up correctly wins, chest waits.

## Required before approval

- None.

---

## Evidence

Game QA / Red Team

## Verdict

PASS

## Score impact

Reliability: 4/5

## What works

- Rank-up is server-set and acknowledged once.
- Every catalog cue has a file in tests.
- Previous buzz/join tests still pass.

## Boring test

Still a race, not a questionnaire.

## Required before approval

- None.

---

## Evidence

Gameplay Designer

## Verdict

PASS WITH NOTES

## Score impact

Gameplay: 4/5
Replayability: 3/5

## What works

- The same verbs now have a voice. First buzz and rank-up feel like events.

## What feels weak

- Mime and statue are still cards. This slice did not add a new verb.

## Highest-value improvement

Statue / mime as the next slice. Mandatory if we want another remembered night.

## Required before approval

- None for M2.

---

## Evidence

Remote Play Designer

## Verdict

PASS

## Score impact

Remote: 4/5

## What works

- Remote players hear and see the same rank-up and finale. Not spectator leftovers.

## What feels weak

- Unchanged: hosted physical rounds.

## Required before approval

- None for this slice.

---

## Night director

M2 approved. Gate still holds. Total moves 58 → 60. Major milestone 64 is not reached.

Next slice: **statue / mime as real verbs** (room puts the phone down; remote holds or guesses). That is the memory the vision already named.
