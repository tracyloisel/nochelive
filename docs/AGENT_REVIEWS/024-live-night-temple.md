# 024 — Live night temple celestial UI

Reviewed: 2026-08-25
Slice: temple visual refonte for live night surfaces (not street)
Tests: `bin/rails test` — 473 runs, 5010 assertions, 0 failures (94.42% coverage); `test/system/night_temple_visual_test.rb` — 2 runs, 0 failures
Gate: `.cursor/skills/noche-night/SKILL.md`
Copy: N/A — no new strings

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | One gold next on marble desk; cream caption on still |
| Equipo en sala | Buzz / move / laugh — unchanged verbs, temple chrome only |
| Jugador en casa | Grade A/B rounds unchanged; arched marble sheet on play |
| Espectador | Cinema watch + short scoreboard strip with gold hairline |

## Tension

Visual only. Night bands, finale stakes, and four-seat verbs unchanged. Temple chrome must not shrink the painting peek or add LIVE chip / story costume on join.

## Finale

Ceremony gets gold arch frame + ink score hero (gold emblem metal only). `scored_finale?` gate unchanged. Gran final can still flip the crown.

## Languages

N/A

## Verdict

PASS WITH NOTES

## What works

- Shared `--temple-*` tokens on `:root` (street + live night).
- Play reel: arched marble sheet, apex star, star bookends on ticks, marble score pill, gold timer bar, choice pills with gold hairline.
- Watch: gold hairline on scoreboard strip.
- Presenter: marble `stage-desk`, gold `code-chip`, tick star bookends.
- Join / lobby / pick / finale reels: same arched sheet treatment.
- Ceremony: gold arch frame, ink score, marble podium steps.
- `config/media/chapel_world.yml`: meetinghouse setting with temple-quality luminous light (no literal temple interior).

## What feels weak

- Live night stills not regenerated yet — `chapel_world.yml` brief updated; run media pipeline separately.
- Watch/presenter temple chrome is lighter than play (by design — overlay scrims stay).

## Required before approval

- None for CSS/docs slice.

## Evidence

UI soul + noche-ui updated for live night temple kit. SFX unchanged (`stage_controller`). Screenshots: `tmp/night-shots/temple-themed/`.

## Night director

Would I still buzz on round 3 with this chrome? Yes — the painting peeks, timer reads, one gold CTA on presenter. Temple is skin, not a new product.
