# 028 — Live night temple seat mockups

Reviewed: 2026-08-25
Slice: high-fidelity temple mockups for the four live-night seats (same round: *La elección de Salomón*)
Tests: N/A — visual target only (no code in this slice)
Gate: `.cursor/skills/noche-ui/SKILL.md` + `.cursor/skills/noche-night/SKILL.md`
Copy: N/A — Spanish UI in the paintings matches existing `t()` / game YAML

## Four seats

| Seat | Verb in the mockup |
|---|---|
| Presentador | One gold **Cerrar buzzer**; Más quiet; marble desk peek (Respuestas / Marcador) |
| Equipo en sala | Slam the gold **Buzz** medallion — chapel is loud |
| Jugador en casa | Grade A QCM: pick Sabiduría (gold border + star) |
| Espectador | Cinema TV: still + question + one scoreboard strip (opt-in Solo ver) |

## Tension

Visual only. Round 1 of 14, Descubrimiento. Buzzer still makes the room move; casa is not “OK when the room is done.”

## Finale

Untouched. These frames are mid-night, not Gran final.

## Languages

Paintings are Spanish (source of truth). No new locale keys.

## Files

`tmp/night-shots/temple-mockups/`

| File | Surface |
|---|---|
| `mockup-night-presenter-temple.png` | `#night_presenter` phone stage |
| `mockup-night-watch-temple.png` | `#night_watch` 16:9 TV |
| `mockup-night-casa-quiz-temple.png` | `#night_play` remote QCM |
| `mockup-night-sala-buzz-temple.png` | `#night_play` room buzzer |

Street visual cousins: `tmp/street-shots/temple-mockups/mockup-street-jugar-temple-adventure.png`

## Verdict

PASS WITH NOTES — mockups only. Product CSS already has a lighter temple pass (`tmp/night-shots/temple-themed/`). These frames are the north star for a later polish loop.

## What works

- Shared still (Solomon + oculus beam) so the four seats feel like one night.
- Ink for questions; gold as metal (arch, stars, one CTA, Buzz disc, scores as metal).
- Watch is cinema: no sheet, no LIVE chip, short caption, one lower-third board.
- Presenter dock is a single gold next; Lista / Fichas live on the desk.
- Casa QCM matches the jugar arched sheet (picked = gold border + star).
- Sala job is the slam, not a seated form.

## What feels weak

- Presenter desk peek is taller than a true `peek` (painting still reads).
- Watch board uses gold numerals on marble — allowed as score-as-metal; do not gold the team names in CSS.
- Casa lockup is ink **Noche Live** (product may keep mute + ticks without a brand wordmark).
- Literal temple-interior still is the round painting (Solomon); chrome is celestial marble, not a Christus set.

## Required before approval

- None for this mockup slice. A later tick should close CSS gaps against these four files the way tick 3 closed `/jugar` against the street adventure mockup.

## Night director

Would I still buzz on round 3 with this chrome? Yes — the painting peeks, the Buzz is a gong, casa has a real pick, the TV is a board, the host has one gold next.

---

Reviewed: 2026-08-26 (night seat loop tick 1)

Slice: `#night_play` three-band temple phone vs `mockup-night-sala-buzz-temple.png` + `mockup-night-casa-quiz-temple.png`
Tests: `PARALLEL_WORKERS=1 bin/rails test test/controllers/play_controller_test.rb test/integration/ui_chrome_test.rb test/system/night_temple_visual_test.rb test/system/play_reel_visual_test.rb` — 27 runs, 1031 assertions, 0 failures
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A — lockup is brand **Noche Live** / LIVE hairlines (ink, not a LIVE chip)

## Night seat loop (tick 1)

P0: play was still a Stories overlay (ticks + dark timer on the painting). Mockups are a **cream temple head** + rounded still + ivory sheet.

| Change | Why |
|---|---|
| `.play-round.is-night-live` three-band grid | Head / still / sheet like jugar, without a street level rail |
| `.night-quiz-head` ink lockup + story ticks + marble timer | Timer is an object on cream, not a dark bar on the light-beam |
| Score pill on the still; night title clipped | Mockup lockup is Noche Live; `story-night` stays for tests |
| Casa ask: no grab-handle; QCM marks hidden | Picked = gold border + star; sala keeps grip + Buzz |
| `play-quiz-casa` visual shot | Remote Salomón QCM seat now has a faithful shot |

Mute + flag stay. Join / watch / presenter CSS untouched.

Screenshots: `tmp/night-shots/temple-themed/play-buzz-open.png`, `play-quiz-casa.png`

### Remaining gaps vs mockups

| Surface | Gap | P |
|---|---|---|
| Watch | Phone portrait, not 16:9 cinema; mute/flag on TV; board not marble strip | P0 |
| Presenter | Desk peek vs mockup tabs; CTA copy follows live phase (Cerrar ronda vs Cerrar buzzer) | P1 |
| Sala Buzz | Medallion already gold; still flatter than mockup gong + “¡Sé el primero!” density | P1 |
| Casa QCM | Three rounded-rects land; picked star on tap is CSS-ready, not in the idle shot | P2 |
| Watch / presenter | No `watch-board-desktop` shot yet | P1 |

## Verdict

PASS WITH NOTES — tick 1 closes play three-band P0 for sala + casa. Watch 16:9 is tick 2.

