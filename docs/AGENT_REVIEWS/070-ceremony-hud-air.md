# 070 — Street ceremony title air under HUD

Reviewed: 2026-08-27
Slice: pack-complete shout sits with token air under the sticky HUD (was 0.15rem). Night ceremony untouched.
Tests: `bin/rails test test/system/street_quiz_visual_test.rb -n "pack ceremony on last question"` — 1 run, 29 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: N/A

## Feeling

The hall opens. The shout is a beat, not a collision with the score capsule.

## 1 — Game experience

First frame of pack-complete: HUD (who I am / 10/10 / score) then a pause, then INCROYABLE. Cramped type under the capsule reads as a UI leak, not a ceremony.

## 2 — UI design

HUD `margin-bottom: var(--space-6)`. Hero `gap` + `padding-top: var(--space-2)`. System assert ≥ 32px between HUD bottom and shout. Gold CTA still first-fold.

## 3 — Art direction

Celestial Light gateway unchanged. Gold metal shout, ink kicker. Air is composition.

## Theme engine

N/A.

## Four seats

Street — un siège (tú). N/A live.

## Tension

The title can land.

## Finale

N/A night.

## Languages

N/A.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.2 |
| Clarté | 8.6 |
| Impact visuel | 8.4 |
| Feedback | 8.2 |
| Progression | 8.1 |
| Social | 8.0 |
| Immersion | 8.4 |
| Accessibilité | 8.3 |
| Cohérence NocheLive | 8.5 |
| Envie de continuer | 8.3 |

## Verdict

**PASS** — title clears the HUD.

## What works

- Token gap, not a magic 2px
- Locked by `assert_ceremony_title_clears_hud`

## What feels weak

- Share / défi can still sit tight on 390 if a waiting note is present (KEEP live)

## Required before approval

- None after visual test green.

## Evidence

`tmp/street-shots/temple-themed/ceremony-phone.png` vs `mockup-street-ceremony-celestial-light.png`

## Night director

Would I play another pack? The shout now has a stage to land on.
