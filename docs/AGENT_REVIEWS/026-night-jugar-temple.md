# 026 — Night live jugar temple polish

Reviewed: 2026-08-25 (tick 3)
Slice: night play / watch / presenter / join vs `mockup-street-jugar-temple-adventure.png`
Tests: `test/system/night_temple_visual_test.rb` — pending tick 3 close
Parent: `docs/AGENT_REVIEWS/025-temple-polish-loop.md`

## Gap matrix (night live)

| Surface | Gap | Priority | Fixed? |
|---|---|---|---|
| Play quiz | Gold arch frame merging shot + chrome | P0 | **yes** tick 2–3 |
| Play | Celestial star bookends on progress rail | P0 | **yes** tick 2–3 |
| Play quiz | Temple ivory sheet (no glass blur) | P0 | **yes** tick 3 |
| Play quiz | Ink question + gold hairline choice pills | P0 | **yes** tick 3 |
| Play | Score star pill top-right | P1 | **yes** tick 3 |
| Play quiz | Cinematic still prominence (lower sheet) | P1 | **yes** tick 3 |
| Play buzz | Rival / presence chip (mockup Carmen +5) | P2 | no — night has team presence, not street rival |
| Play | NOCHE LIVE brand lockup in chrome | P3 | no |
| Watch | Gold arch on still + lighter top scrim | P1 | **yes** tick 2–3 |
| Presenter | Gold arch on stage still + marble desk | P1 | **yes** tick 2–3 |
| Join | Arched ivory sheet + ink copy | P1 | yes (prior slice) |
| Media | `chapel_world.yml` stills not regenerated | P2 | no — OpenRouter pipeline |

## Tick 3 fixes

- **Play chrome**: transparent scrim (painting peeks); gold arch on `play-shot` + `play-chrome::before` merge.
- **Progress rail**: marble pill ticks with star bookends; gold dot ticks (not dark story bars).
- **Quiz sheet**: solid ivory gradient, `backdrop-filter` removed, 2px gold border, lower `max-height` for still peek.
- **Quiz copy**: ink `prompt`, display font; choice pills gold hairline + shorter height.
- **Score**: `story-score` absolute top-right; quiz hides night title cluster, close stays left.
- **Watch**: lighter `watch-chrome` gradient over still.

## Screenshots (tick 3)

`tmp/night-shots/temple-themed/` — join-sheet, play-buzz-open, play-quiz-ask, watch-board, presenter-stage, presenter-desk-open.

Mockup ref: `tmp/street-shots/temple-mockups/mockup-street-jugar-temple-adventure.png`

## Iteration 4 priorities

1. **P2** — Night rival/presence chip styling toward mockup Carmen pill (if product wants parity).
2. **P2** — Run `script/generate_quiz_media.rb` when `OPENROUTER_API_KEY` set.
3. **P3** — Subtle Noche Live ink lockup under arch (no gold type on cream).
4. **P3** — Desktop play-ask shot (`play-quiz-ask-desktop`).

## Verdict

PASS WITH NOTES — tick 3 closes jugar mockup gaps on night play quiz; street rival chip and brand lockup remain.
