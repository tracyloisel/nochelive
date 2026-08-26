# 033 — Leftover screens on paper hall

Reviewed: 2026-08-26
Slice: non-mockup surfaces (join, gates, desks, lobby residue) onto `/quien` hall chrome
Tests: controller + ui_chrome for those routes; `bin/rails test` in the same change
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (existing `t()` keys only)

## Four seats

N/A for hall surfaces. Live leftover (lobby / pick-team / rank-up) keep the three-band still; only Stories residue came off.

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged console; gate/claim wait are hall, one gold, no X |
| Equipo en sala | Unchanged Buzz reel; lobby no longer shows LIVE |
| Jugador en casa | Unchanged QCM reel |
| Espectador | Unchanged TV; Solo ver stays quiet on rama |

## Tension

N/A. No round YAML moved.

## Finale

Unchanged `.ceremony-temple`. Rank-up / chest gold is a row button, not `picto-btn`.

## Languages

No new strings.

## Verdict

PASS WITH NOTES

## What works

- Shared `paper_hall` + `.hall-sheet` (alias `.street-quien-sheet`).
- Join, presenter gate, ward gate, fichas, roster, rama, nosotros, souvenir sit on marble + ivory sheet.
- Painting on those desks is a card (`.hall-still`), not a fake reel.
- `/home` redirects to `/`. Hub wizard is an inline marble panel.

## What feels weak

- Live round types still use `picto-btn` on Send (out of this slice).
- Join in a signed-in browser skips straight to play — expected.

## Required before approval

- None for chrome. Full `bin/rails test` should stay ≥ 90% in the same change.

## Night director

Would I play another round? Yes — leftover forms no longer look like Stories on a card. The four live seats were not restyled.
