# M135 — Celestial Light luminous depth

Reviewed: 2026-08-29
Slice: Hub `/`, Light atmosphere and shared hero geometry
Tests: controller 30 runs / 597 assertions; system 1 run / 15 assertions; 0 failures, 0 errors
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no copy, content rule, destination, timing, or notification changed

## Feeling

Wonder and invitation. Celestial Light must feel like entering a radiant biblical world, not reading ivory cards laid over a wallpaper.

## 1 — Game experience

The street loop is unchanged: the player sees identity and progress, anticipates the next pack, taps the gold **Jouer** verb, receives the existing reward and progress feedback, then sees the next desire. The visual pass makes the current adventure easier to want without adding a decision, wait, or administrative step.

## 2 — UI design

The two-second verb remains **Jouer**. Light now uses semantic pearl, sky, navy-ink, living-gold, border, shadow, glass, button, and glow tokens. The hero illustration fills its track at tablet/desktop instead of exposing a dead ivory strip. Copy protection is local and bounded; the artwork, reward and CTA remain visible. Existing idle, pressed, loading, success, failure, locked, unlocked, completed, new and live behavior is preserved.

## 3 — Art direction

Celestial Light keeps the Eden/garden artwork bright while gaining dark-family depth through navy-tinted shadows, a pearl/sky glass spectrum, localized warm ivory and metallic gold glints. The hero face and landscape remain visible; the study, Live, social, progression, community, HUD and dock no longer collapse into one beige value. Celestial Dark retains its night-blue surfaces and volumetric gold.

## Theme engine

PASS. One Hub and one markup tree still serve both theme families. Every new atmospheric decision is scoped to `[data-hub-theme="light"]` or the Light body class; the artwork manifest still selects Light/Dark deterministically and no user toggle was introduced.

## Four seats

N/A — street Hub. The screen still answers who I am, where I am, what I should do now, and what is happening around me.

## Tension

Street loop only. The stronger gold verb, visible reward and preserved artwork make the current pack feel actionable while locked and future progression remain legible below.

## Finale

N/A — no round, score or ceremony logic changed.

## Languages

N/A — no localized copy changed.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- The Light world reads as luminous and dimensional rather than white and flat.
- Local glass protects copy without bleaching the subject or the landscape.
- Gold CTA, navy secondary action, HUD and dock now form a clear Noche visual rhythm.
- Light and Dark keep identical geometry, including a fully filled 20rem desktop hero.

## What feels weak

- Highly luminous source paintings still need local glass by design; removing it entirely would fail outdoor and older-player contrast.

## Required before approval

- None.

## Evidence

- Personally inspected Light and Dark at 390 × 844, 768 × 1024 and 1440 × 900.
- Screenshots reviewed against both Hub theme mockups and the supplied production capture.
- Menu open/close exercised; primary, secondary and dock targets measured at 44px or greater.
- No horizontal overflow at the three required viewports.
- Browser console: 0 warnings and 0 errors caused by the slice.
- `bundle exec rails test test/controllers/street_hub_controller_test.rb`: 30 runs, 597 assertions, green.
- `bundle exec rails test test/system/home_smoke_test.rb`: 1 run, 15 assertions, green.
- One earlier combined run hit an unrelated PostgreSQL deadlock in `DuelInvitation#refresh_public_token!`; the failed test and both suites passed cleanly after the temporary QA server was stopped.
- Editorial approval: N/A; no player-visible messaging or selection behavior changed.

## Night director

Yes. The first impression is now a world and a reward worth entering, while **Jouer** remains the unmistakable next action.
