# M77 — Jugar responsive game board

Reviewed: 2026-08-27
Slice: `/jugar` ask, timed ask, miss, hit, and next-turn layouts at every CSS breakpoint
Tests: `bin/rails test test/system/street_quiz_visual_test.rb -i street_quiz_sheet_type_miss_ticks_and_swipe` — 1 run, 3253 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — N/A; no copy moved

## Feeling

Pressure without obstruction: the player always sees the complete hand of answers, while the biblical painting, timer, result, and next desire keep their hierarchy.

## 1 — Game experience

The answer remains the immediate verb. Short portrait screens compact the glass rather than crop a choice. Short-wide screens become a full game board with one horizontal answer hand, so landscape is no longer a phone slit with hidden results. Hit/miss, scripture, next, score, combo, and timed tension remain intact.

## 2 — UI design

Exact 320×568, 360×640, 390×844, 430×932, 768×1024, 844×390, 1024×768, and 1440×900 CSS viewports are captured and geometry-checked. HUD, sheet, timer, actions, and every answer must remain inside the viewport; answer targets stay at least 36px in the compact test matrix. The 320px HUD prioritizes player identity over repeating the pack title.

States covered: ask, pressed/locked through the existing quiz controller, miss, correct, next ask, timed live, reduced motion through the existing rule.

## 3 — Art direction

Portrait keeps the tall adventure composition. Short-wide uses the entire cinematic frame and places the answer hand as a low glass band, restoring the painting’s scale and avoiding black side gutters. Celestial Light/Dark continue to come from each still.

## Theme engine

N/A — not the hub.

## Four seats

N/A — street solo. The player’s job is still pick → result → reward → next.

## Tension

The readable timer remains on the still. Compact rules never remove feedback or the next action; they only change composition to preserve the loop under height pressure.

## Finale

N/A — pack ceremony unchanged.

## Languages

N/A — no user-facing string changed. Existing translated copy is laid out, not rewritten.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- No tested answer, timer, result bar, scripture action, or next action clips at any breakpoint.
- Landscape reads as a deliberate game-board composition instead of a cropped portrait fallback.

## What feels weak

- Extremely long future answer copy can still wrap; geometry tests guard the viewport, but editorial brevity remains important.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/temple-themed/01-ask-*`
- `tmp/street-shots/temple-themed/02-miss-*`
- `tmp/street-shots/temple-themed/03-right-*`
- `tmp/street-shots/temple-themed/06-timed-*`

## Night director

Yes. Every tested orientation preserves the pressured pick and reveals the reward without making the player hunt or scroll for the verb.
