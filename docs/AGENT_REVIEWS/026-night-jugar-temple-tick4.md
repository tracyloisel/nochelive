# 026 — Night jugar temple tick 4

Reviewed: 2026-08-25 (tick 4 / shell occurrence 3)
Slice: night live play/watch/presenter/join gold-arch parity vs `mockup-street-jugar-temple-adventure.png`
Tests: `test/system/night_temple_visual_test.rb` — 4 runs (arch + quiz-ask assertions); full suite pending CI (local PG fixture contention when parallel agents run)
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A — no new strings

## Gap matrix (tick 4 delta)

| Screen | Gap | Priority | Fixed? |
|---|---|---|---|
| Night play | Outer gold arch on still + apex arch (street jugar parity) | P2 | **yes** tick 4 |
| Night play | Marble pill on story-ticks + star bookends | P1 | yes (tick 3) |
| Night play | Remote phone-quiz ask reel shot | P2 | **yes** tick 4 (`play-quiz-ask`) |
| Night watch | Gold arch on watch-shot + chrome apex | P2 | **yes** tick 4 |
| Night presenter | Gold arch on stage-shot + marble tick pill | P2 | **yes** tick 4 |
| Night join | Gold arch on play-shot during join sheet | P2 | **yes** tick 4 |
| Street jugar | Rival chip on still (avatar + gap pill) | P1 | **yes** tick 4 (`street-shot-rival`) |
| Street jugar | Broken `unless/elsif` in chrome ERB | P0 | **yes** tick 4 |
| Hub league panel signed-in shot | P1 | no — needs fixture profile |
| Ceremony temple interior scrim | P0 | **yes** tick 3 (street + night finale) |
| Media stills regeneration | P2 | no — OpenRouter not run |
| Hub / reel NOCHE LIVE lockup | P3 | no |

## Tick 4 fixes

- **Night play / join / lobby / pick / finale**: `play-shot::before/after` gold arch matches street jugar frame (3.5px border, apex arch, chrome `::before` halo). Story-ticks marble pill retained.
- **Night watch / presenter**: matching gold arch on `watch-shot` / `stage-shot`; presenter ticks in marble pill.
- **Street jugar**: rival moved to `street-shot-rival` on still (horizontal avatar + name + gap pill); fixed chrome ERB branch for score vs rank.
- **Tests**: `night_temple_visual_test` asserts arch pseudo-elements + remote Salomón phone-quiz ask path.

## Screenshots (tick 4)

Night: `tmp/night-shots/temple-themed/` — `join-sheet`, `play-buzz-open`, `play-quiz-ask`, `watch-board`, `presenter-stage`, `presenter-desk-open`.

Mockup target: `tmp/street-shots/temple-mockups/mockup-street-jugar-temple-adventure.png`.

## Iteration 5 priorities

1. **P1** — Hub league panel visible shot with signed-in street profile (`hub-league-phone`).
2. ~~**P0** — Ceremony temple interior scrim behind victory frame (street + night finale).~~ **done tick 3** — see `026-night-jugar-temple-tick3.md`.
3. **P2** — Run `script/generate_quiz_media.rb` when `OPENROUTER_API_KEY` set.
4. **P3** — Subtle ink brand lockup under oculus on hub (not on live reel).

## Verdict

PASS WITH NOTES — night live surfaces now share street jugar gold-arch grammar; mockup photo interiors and media pipeline remain.
