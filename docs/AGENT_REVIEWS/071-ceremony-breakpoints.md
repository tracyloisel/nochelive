# 071 — Street ceremony across play-column breakpoints

Reviewed: 2026-08-27
Slice: `/jugar` pack-complete HUD + stack pin to `--street-play-col` at 720 / 1024 / 1440; short-height compact; title air kept. Night ceremony untouched.
Tests: `bin/rails test test/system/street_quiz_visual_test.rb -n "/ceremony/"` — 2 runs, 80 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: N/A

## Feeling

The hall is a phone arch on every glass, not a stretched web header. The shout still lands. The gold map stays the verb.

## 1 — Game experience

Same loop. Desktop 800px tall no longer eats the CTA. iPad/XL no longer turn the HUD into a cinema-wide cream strip.

## 2 — UI design

HUD + ceremony stack `min(--street-play-col)`. Burger tracks the arch. `max-height: 860px` shrinks medal/chest. Title gap ≥ 32px except SE (`667px`).

## 3 — Art direction

Gateway still full-bleed. Chrome is the phone column. Gold medal scales with height, not window width.

## Theme engine

N/A.

## Four seats

Street — un siège (tú). N/A live.

## Tension

N/A.

## Finale

N/A night.

## Languages

N/A.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.2 |
| Clarté | 8.5 |
| Impact visuel | 8.4 |
| Feedback | 8.2 |
| Progression | 8.1 |
| Social | 8.0 |
| Immersion | 8.4 |
| Accessibilité | 8.3 |
| Cohérence NocheLive | 8.6 |
| Envie de continuer | 8.3 |

## Verdict

**PASS** after visual green at 390 / 768 / 1280×800 / 1920.

## What works

- Column pin + short-height compact
- Locked by `assert_ceremony_breakpoints!`

## What feels weak

- Live 1/10 and `00:00` on the jump-to-Q10 shot (KEEP)
- Share can still sit on the last 72px of a 844 phone when a duel waiting note is present

## Required before approval

- Visual test green.

## Evidence

`ceremony-phone.png` / `jugar-ceremony-ipad.png` / `jugar-ceremony-desktop.png` / `jugar-ceremony-xl.png`

## Night director

Would I play on an iPad? Now the HUD is a game capsule, not a browser toolbar.
