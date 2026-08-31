# M165 — Hub voyage dots only

Reviewed: 2026-08-31
Slice: Hero slideshow position control
Tests: `bundle exec rails test test/system/hub_streaming_rails_visual_test.rb` — 2 runs, 1129 assertions, 0 failures; targeted controller contract — 1 run, 11 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: N/A — the voyage content and Play loop are unchanged
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no player-facing copy changed

## Feeling

The Hero should reveal that another chapter exists without presenting a second control bar beside Play.

## 1 — Game experience

Swipe and direct dot selection remain. Previous/next arrows and the numeric counter no longer compete with the primary action.

## 2 — UI design

Only position dots are painted. Their invisible button boxes remain 44×44 px, retain native keyboard activation and expose a specific accessible label for each slide. The active point stretches and turns gold; inactive positions stay quiet.

## 3 — Art direction

The glass capsule, arrows and counter were removed. Desktop dots sit in unused artwork space at the right; tablet and phone dots sit below the cockpit. No extra surface covers either Celestial artwork family.

## Theme engine

The same transparent control consumes Light and Dark semantic text/gold tokens. No theme toggle or duplicated Hero markup was introduced.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.8 |
| Clarté | 9.7 |
| Impact visuel | 9.5 |
| Feedback | 9.2 |
| Progression | 9.2 |
| Social | 9.0 |
| Immersion | 9.6 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9.6 |
| Envie de continuer | 9.2 |

## Verdict

PASS

## What works

- The slideshow is visible without reading as another CTA.
- Every painted control is now a position point.
- Swipe, click, keyboard focus, reduced motion and forced colors remain supported.
- The desktop dots no longer collide with the leaderboard cockpit.

## What feels weak

- None within this slice.

## Required before approval

- None.

## Evidence

- Celestial Light and Dark visually inspected at 768×1024 and 1440×900.
- The full 320–1920 px visual matrix passes without console errors or horizontal overflow.
- Tests assert there are no voyage arrows or numeric counter and no painted navigation container.

## Night director

Yes. The dots whisper “there is more” while Play remains the unmistakable verb.
