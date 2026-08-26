# 026 — Night live jugar polish loop (iteration 1)

Reviewed: 2026-08-25
Slice: `#night_play`, `#night_watch`, `#night_presenter`, join/lobby/pick/finale vs `mockup-street-jugar-temple-adventure.png`
Tests: `bin/rails test` — 482 runs, 94.25% line coverage; visual suite 5/5 when DB uncontended
Gate: `.cursor/skills/noche-ui/SKILL.md`

## Gap matrix (night vs jugar mockup)

| Screen | Gap | Priority | Fixed? |
|---|---|---|---|
| Night play | Outer gold arch + apex on `.play-shot` | P0 | **yes** iter 1 |
| Night play | Celestial level rail — ivory marble pill, star bookends, dot pulse | P0 | **yes** iter 1 |
| Night play | Cream ivory sheet + apex star + gold hairline choices | P1 | yes (prior slice) |
| Night play | Score star pill (ink, gold picto) | P1 | **yes** iter 1 (pill sizing) |
| Night play | Rival / presence chip prominence | P2 | partial — night uses audience not rival |
| Night play | Full-bleed peril+grace still quality | P2 | no — `chapel_world.yml` not regenerated |
| Night play | NOCHE LIVE brand lockup in chrome | P3 | no — reel has night title only |
| Night watch | Gold arch on `.watch-shot` | P0 | **yes** iter 1 |
| Night watch | Scoreboard emblem gold hairline | P1 | yes (tick 2) |
| Night watch | Cinema caption stays scrim (not ivory sheet) | — | by design (TV) |
| Night presenter | Gold arch on `.stage-shot` | P0 | **yes** iter 1 |
| Night presenter | Marble desk + star ticks pill | P1 | **yes** iter 1 |
| Join / pick / lobby | Sheet + shot arch parity | P1 | **yes** iter 1 |
| Ceremony / finale | Gold arch frame on hero | P1 | yes (prior slice) |
| Media | OpenRouter adventure stills | P2 | no — key not run |

## Iteration 1 fixes

- **Play / join / lobby / pick / finale**: `.play-shot::before/::after` gold border + apex arch; `.play-chrome::before` arch echo; `.story-ticks` ivory marble pill with celestial star bookends and `night-tick-pulse` on current dot.
- **Watch**: matching gold arch on `.watch-shot`; chrome arch hint.
- **Presenter**: gold arch on `.stage-shot`; consolidated `.stage-ticks` marble pill + star bookends.
- **Visual test**: `night_temple_visual_test.rb` asserts arch pseudo-elements; adds `play-quiz-ask` shot for Salomón choice round.

## Screenshots (iteration 1)

`tmp/night-shots/temple-themed/`:

- `join-sheet.png`
- `play-buzz-open.png`
- `play-quiz-ask.png` (new)
- `watch-board.png`
- `presenter-stage.png`
- `presenter-desk-open.png`

Mockup reference: `tmp/street-shots/temple-mockups/mockup-street-jugar-temple-adventure.png`

## Iteration 2 priorities

1. **P1** — Night play chrome row: score pill + night title sizing to match mockup density (rival chip N/A for live night).
2. **P1** — Lobby / pick-team / finale dedicated visual shots (`lobby-mid`, `pick-team`, `finale-ceremony`).
3. **P2** — Watch caption: optional ivory question strip for `choice?` rounds without breaking cinema scrim on other round types.
4. **P2** — Run `script/generate_quiz_media.rb` when `OPENROUTER_API_KEY` set for chapel peril+grace stills.
5. **P3** — Presenter stage: gold hairline on `code-chip` row alignment with arch apex.

## Verdict

PASS WITH NOTES — iteration 1 closes P0 arch + celestial rail gaps on all live night surfaces; still quality and lobby/finale shots remain iteration 2.
