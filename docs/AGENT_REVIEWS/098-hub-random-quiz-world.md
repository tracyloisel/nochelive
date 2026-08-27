# 098 — Hub random quiz world

Reviewed: 2026-08-28
Slice: a fresh biblical world on each Home visit
Tests: `bin/rails test test/services/hubs/backdrop_test.rb` — 9 runs, 28 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no player-facing copy changed

## Feeling

Curiosity and renewed wonder: opening Home should feel like entering another part of the biblical adventure.

## 1 — Game experience

Each Home visit draws from the curated quiz-world catalog and avoids the immediately previous still. The core loop and primary Jouer action remain unchanged.

## 2 — UI design

The same Hub markup and hierarchy remain in place. Every selected still retains its semantic Light/Dark theme, atmosphere, and gold accent, so existing contrast and interaction states continue to apply.

## 3 — Art direction

The background remains a narrative layer drawn from quiz paintings, not a generic wallpaper. The curated manifest protects composition and readability while varying world, light, and mood.

## Theme engine

One Home, one manifest, no user toggle. Randomness chooses the artwork; the artwork deterministically chooses its Celestial Light/Dark family.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- No immediate repeat for the same browser session.
- Light/Dark remains authored per artwork rather than inferred at render time.
- A one-entry catalog remains safe and the existing deterministic API is preserved for other screens.

## Required before approval

- None.

## Night director

Yes: the changing world creates anticipation before the player even presses Jouer, without delaying or obscuring the action.
