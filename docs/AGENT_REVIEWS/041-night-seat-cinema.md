# 041 — Live night seats across breakpoints

Reviewed: 2026-08-26
Slice: sala Buzz, casa QCM, TV watch, presenter stage — mockup chrome at phone / tablet / desktop
Tests: `PARALLEL_WORKERS=1 bin/rails test` — 645 runs, 7158 assertions, 0 failures. Coverage 94.71%.
Gate: `.cursor/skills/noche-ui/SKILL.md` + `.cursor/skills/noche-night/SKILL.md`
Copy: N/A — reused `play.casa_team` / `play.first_hint`; no new keys

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | One gold next; marble desk peek (Lista / Fichas, Respuestas / Marcador) |
| Equipo en sala | Slam the gold Buzz medallion — `¡Sé el primero!` |
| Jugador en casa | Grade A/B on ivory QCM; Casa chip on the still |
| Espectador | Opt-in Solo ver — 16:9 cinema from 720px, marble score strip |

## Tension

Unchanged. Descubrimiento still opens on Salomón. Chrome only.

## Finale

Untouched.

## Languages

N/A — no new copy. Mute hidden on TV; language flag stays reachable (i18n mid-quiz).

## Verdict

PASS WITH NOTES

## What works

- Play three-band: close X in the cream head; team / Casa chip on the still; score pill stays on the painting.
- Sala Buzz is a metal disc with a glow ring; hint reads as ink, hidden only on short phones so the slam stays on the first fold.
- Watch: gold code chip, corner stars, marble lower-third (ink names, gold scores), mute off the TV. From 720 the board is a 16:9 frame on the hall.
- Presenter desk peek is shorter (0.26) so Solomon still reads; tabs are an ink underline, not a second gold CTA.

## What feels weak

- Phone portrait watch is still full-bleed 9:16 cinema chrome, not a letterboxed 16:9 strip (unusable on a handset).
- Sala hint `¡Sé el primero!` yields to the first-fold test on 667-tall phones.
- Next tick: compare recaptured shots to mockups; tighten presenter desk peek vs Solomon’s face.

## Required before approval

- Visual shots recaptured: `play-buzz-open`, `play-quiz-casa`, `watch-board` + desktop/cinema, `presenter-stage`.

## Night director

Would I still buzz on round 3? Yes — the painting peeks, casa has a named seat, the TV is a board, the host has one gold next.
