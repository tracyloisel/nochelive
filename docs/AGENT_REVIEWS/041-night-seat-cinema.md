# 041 — Live night seats across breakpoints

Reviewed: 2026-08-26
Slice: sala Buzz, casa QCM, TV watch, presenter stage — mockup chrome at phone / tablet / desktop
Tests: `bin/rails test` — 677 runs, 7486 assertions, 0 failures. Coverage 94.84%.
Gate: `.cursor/skills/noche-ui/SKILL.md` + `.cursor/skills/noche-night/SKILL.md`
Copy: N/A — reused `play.casa_team` / `play.first_hint`; no new keys

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | One gold next; marble desk peek 0.28 (Lista / Fichas, Respuestas / Marcador, first buzz row) |
| Equipo en sala | Slam the gold Buzz medallion — `¡Sé el primero!` on the first fold (hidden only at ≤667px) |
| Jugador en casa | Grade A/B on ivory QCM; Casa chip on the still |
| Espectador | Opt-in Solo ver — 16:9 cinema from 720px; landscape phones keep the 1fr / auto cinema grid (caption on the still, marble strip as row 2) |

## Tension

Unchanged. Descubrimiento still opens on Salomón. Chrome only.

## Finale

Untouched.

## Languages

N/A — no new copy. Mute hidden on TV; language flag stays reachable (i18n mid-quiz). Flag pins to the cinema frame from 720px.

## Verdict

PASS WITH NOTES

## What works

- Play three-band: close X in the cream head; team / Casa chip on the still; score pill stays on the painting.
- Sala Buzz is a metal disc; hint `¡Sé el primero!` sits under the gong on ~844-class phones. Short 667 hides the hint so the slam stays on the first fold (Selenium inner height is ~701 for the 844 window, so the hide breakpoint is 667 not 720).
- Watch: gold code chip, corner stars, marble lower-third (ink names, gold scores), mute off the TV. From 720 the board is a 16:9 frame on the hall. Landscape phones keep the same 1fr / auto cinema grid so the one-line caption sits just above the marble — not a mid-frame dark banner over the light-beam.
- Presenter desk peek (0.28) keeps Lista / Fichas, Respuestas / Marcador, and a first buzz row on screen; the prophet still reads; tabs are an ink underline, not a second gold CTA.

## What feels weak

- Landscape watch is cinema-on-a-phone: the still is short; Solomon still shares the frame with the hall letterbox.
- Presenter peek shows the first buzz row; the rest of the desk is still a summon.

## Required before approval

- None.

## Night director

Would I still buzz on round 3? Yes — the painting peeks, casa has a named seat, the TV is a board, the host has one gold next, and the sala sheet now says *be first*.
