# 026 — Night jugar temple tick 3

Reviewed: 2026-08-25 (tick 3 / ceremony scrim)
Slice: full-bleed temple interior scrim on street pack ceremony + night finale (play / watch / presenter)
Tests: `test/system/street_quiz_visual_test.rb` (pack ceremony), `test/system/night_temple_visual_test.rb` (play finale), `test/helpers/application_helper_test.rb` (`temple_hall_bg_src`)
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A — no new strings

## Gap closed (tick 3 P0)

| Screen | Gap | Priority | Fixed? |
|---|---|---|---|
| Street ceremony | Full-bleed temple hall scrim hides pack still | P0 | **yes** tick 3 |
| Street ceremony | Gold arch + ink score + pedestal/chest | P0 | yes (tick 2, retained) |
| Night play finale | Temple interior scrim behind ceremony | P0 | **yes** tick 3 |
| Night watch finale | Temple interior scrim behind ceremony | P0 | **yes** tick 3 |
| Night presenter finale | Temple interior scrim behind desk ceremony | P0 | **yes** tick 3 |
| Hub / ceremony bg | Wire OpenRouter `marble-hall.jpg` when present | P1 | **yes** tick 3 |

## Tick 3 fixes

- **`temple_hall_bg_src`** — prefers `public/media/temple/marble-hall.jpg` (OpenRouter), falls back to `temple-marble-hall.svg`; exposed as `--temple-hall-bg` on `:root`.
- **`--temple-hall-scrim`** — shared marble-column + oculus stack for immersive ceremony backgrounds.
- **Street** — `#street_quiz.is-ceremony-immersive` hides play-shot/chrome; full-viewport temple scrim; `.street-ceremony` gold arch + column scrim + pedestal/chest unchanged.
- **Night play** — `.play-reel.is-finale.is-ceremony-immersive` same treatment; sheet opens full height (mid snap bypassed).
- **Night watch / presenter** — `#night_watch.is-ceremony-immersive` and `.console.is-ceremony-immersive` hide still/overlay; ceremony in caption/desk.
- **`shared/_ceremony`** — `.ceremony-temple` with column scrim, triple-star arch crown, gold arch `::before`, ink score hero.

## Screenshots (tick 3)

Street: `tmp/street-shots/temple-themed/ceremony-phone.png`, `jugar-ceremony-desktop.png`.

Night: `tmp/night-shots/temple-themed/play-finale-ceremony.png`.

Mockup target: `tmp/street-shots/temple-mockups/mockup-street-ceremony-temple-victory.png`.

## Remaining (tick 4+)

See `026-night-jugar-temple-tick4.md` — hub league panel shot, media stills regen, NOCHE LIVE lockup.

## Verdict

PASS — ceremony temple interior scrim ships on street pack complete and night finale across play, watch, and presenter; OpenRouter marble hall photo wired when on disk.
