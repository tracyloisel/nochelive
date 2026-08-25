# M21 — Street profile, trail map, sheet peek

Reviewed: 2026-08-25
Slice: street quiz identity, progression path, draggable lower sheet
Tests: `bin/rails test` — 442 runs, 4985 assertions, 0 failures. Line coverage 95.82%.
Gate: `.cursor/skills/noche-ui/SKILL.md`, `.cursor/skills/noche-i18n/SKILL.md`

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged. |
| Equipo en sala | Unchanged once inside a night. |
| Jugador en casa | Unchanged remote A/B. |
| Espectador | Unchanged *Solo ver*. |
| **Street (tú)** | Pick a ficha, see the path, drag the card down, tap a dot to revisit. |

## Verdict

PASS WITH NOTES

## What works

- Signed-in chip on `#street_quiz` when a ward + ficha cookie exist; guest link when not.
- `/quien` reuses the join ficha flow (device list, homonyms, year claim, create).
- Per-person `quiz_runs` when a ficha is active; guest stays device-only.
- Horizontal trail: pack flags + question dots (correct / wrong / current); jump via turbo.
- Sheet grip + lower mid snap (36% viewport); 220ms delayed rise on each question.

## What feels weak

- No ward cookie → no profile chip; user must enter a rama first (search / Benidorm).
- Trail only shows packs reached on this device; no global leaderboard tie-in.
- Finished older packs collapse to dots only on revisit — no inline pack score.

## Required before approval

- None for the slice.

## Night director

Would I play another pack on the family iPad? Yes — I see who I am, where I am on the map, and I can pull the card to admire the still.
